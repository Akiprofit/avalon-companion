import 'dart:async';
import 'dart:math';

import '../model/room_code.dart';
import '../model/room_state.dart';
import '../protocol/table_connection.dart';
import '../protocol/table_message.dart';
import '../protocol/table_protocol.dart';
import 'table_session.dart';

/// The board's side of the protocol: connections in, room state out.
///
/// No `dart:io` and no timers. A socket is a [TableConnection]; silence is
/// detected by [sweep], which the controller calls on its own clock. That keeps
/// every rule here testable on in-memory connections and lets a PC probe drive
/// a real room without a Flutter binding.
class TableRoom {
  TableRoom({
    required String code,
    required this.address,
    required this.port,
    required this.boardName,
    this.capacity = TableProtocol.capacity,
    Random? random,
    DateTime Function()? clock,
  }) : _session = TableSession(code: code, capacity: capacity, random: random),
       _clock = clock ?? DateTime.now;

  final String address;
  final int port;
  final String boardName;
  final int capacity;

  final TableSession _session;
  final DateTime Function() _clock;

  final Map<String, TableConnection> _connections = {};
  final Map<String, DateTime> _attachedAt = {};
  final Map<String, StreamSubscription<String>> _subscriptions = {};
  final StreamController<RoomState> _states =
      StreamController<RoomState>.broadcast();

  bool _closed = false;

  String get code => _session.code;

  /// The room as the board renders it. No tokens, no private bookkeeping.
  RoomState get state =>
      _session.roomState(address: address, port: port);

  /// Fires on every change to [state].
  Stream<RoomState> get states => _states.stream;

  int get seatedCount => _session.seats.length;

  /// Takes a newly accepted socket. Frames are handled as they arrive.
  void attach(TableConnection connection) {
    if (_closed || _connections.containsKey(connection.id)) return;
    _connections[connection.id] = connection;
    _attachedAt[connection.id] = _clock();
    _subscriptions[connection.id] = connection.incoming.listen(
      (frame) => _onFrame(connection, frame),
      onError: (Object _) => _drop(connection.id),
      onDone: () => _drop(connection.id),
      cancelOnError: false,
    );
  }

  /// Closes the room for everyone. The board uses this when the MC leaves.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;

    final connections = _connections.values.toList();
    _connections.clear();
    _attachedAt.clear();
    // Cancelling stops delivery at once; the future only reports cleanup.
    // Fire-and-forget keeps a stalled socket from blocking the close.
    for (final subscription in _subscriptions.values) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();

    for (final connection in connections) {
      unawaited(
        connection.close(
          code: TableCloseCode.goingAway,
          reason: 'room closed',
        ),
      );
    }
    await _states.close();
  }

  /// Marks silent phones away and drops sockets that never said hello.
  ///
  /// Called on a timer by the controller; a phone that vanished must not hold a
  /// seat in a "connected" state, because the board would be lying to the table.
  void sweep() {
    if (_closed) return;
    final now = _clock();

    for (final id in _session.silentConnections(now, TableProtocol.silentTimeout)) {
      final connection = _connections[id];
      if (connection == null) continue;
      unawaited(
        connection.close(code: TableCloseCode.goingAway, reason: 'silent'),
      );
      _drop(id);
    }

    for (final entry in _attachedAt.entries.toList()) {
      if (_session.seatNumberForConnection(entry.key) != null) continue;
      if (now.difference(entry.value) < TableProtocol.silentTimeout) continue;
      final connection = _connections[entry.key];
      if (connection == null) continue;
      unawaited(
        connection.close(code: TableCloseCode.policy, reason: 'no hello'),
      );
      _drop(entry.key);
    }
  }

  // -------------------------------------------------------------------------
  // Frames
  // -------------------------------------------------------------------------

  void _onFrame(TableConnection connection, String raw) {
    if (raw.length > TableProtocol.maxFrameBytes) {
      _sendError(connection, TableErrorCode.badMessage);
      unawaited(
        connection.close(
          code: TableCloseCode.tooLarge,
          reason: 'frame too large',
        ),
      );
      _drop(connection.id);
      return;
    }

    final result = decodeTableFrame(raw);
    switch (result) {
      case TableDecodeFailure(:final code):
        _sendError(connection, code);
        if (code == TableErrorCode.badMessage ||
            code == TableErrorCode.version) {
          unawaited(
            connection.close(code: TableCloseCode.policy, reason: 'protocol'),
          );
        }
      case TableDecoded(:final message):
        _onMessage(connection, message);
    }
  }

  void _onMessage(TableConnection connection, TableMessage message) {
    switch (message) {
      case HelloMessage(:final code, :final name, :final token):
        _onHello(connection, code: code, name: name, token: token);
      case PingMessage(:final t):
        _session.touch(connection.id, now: _clock());
        connection.send(PongMessage(t: t).encode());
      case LeaveMessage():
        final seat = _session.releaseForConnection(connection.id);
        if (seat != null) _broadcastState();
        unawaited(
          connection.close(code: TableCloseCode.normal, reason: 'left'),
        );
        _drop(connection.id);
      case _:
        _sendError(connection, TableErrorCode.unknownType);
    }
  }

  void _onHello(
    TableConnection connection, {
    required String code,
    required String name,
    String? token,
  }) {
    if (RoomCode.normalise(code) != _session.code) {
      _sendError(connection, TableErrorCode.roomNotFound);
      unawaited(
        connection.close(code: TableCloseCode.policy, reason: 'wrong room'),
      );
      _drop(connection.id);
      return;
    }

    final result = _session.join(
      connectionId: connection.id,
      rawName: name,
      token: token,
      now: _clock(),
    );

    switch (result) {
      case JoinAccepted(
        seat: final seatNumber,
        token: final seatToken,
        displacedConnection: final displaced,
      ):
        if (displaced != null) {
          final old = _connections[displaced];
          if (old != null) {
            old.send(ErrorMessage.of(TableErrorCode.seatReleased).encode());
            unawaited(
              old.close(code: TableCloseCode.normal, reason: 'replaced'),
            );
            _drop(displaced);
          }
        }
        connection.send(
          WelcomeMessage(
            seat: seatNumber,
            token: seatToken,
            code: _session.code,
            capacity: capacity,
            phase: RoomPhase.lobby,
            seats: _session.seats,
          ).encode(),
        );
        _broadcastState();
      case JoinRejected(:final code):
        _sendError(connection, code);
    }
  }

  /// Releases a seat from the board.
  ///
  /// Used for an away phone that is not coming back: the seat disappears for
  /// everyone, and if the phone is somehow still connected it is told why before
  /// its socket closes. A connected seat can be released too — the MC is in
  /// charge of the table, not the phone.
  bool releaseSeat(int seatNumber) {
    if (_closed) return false;
    final connectionId = _session.connectionForSeat(seatNumber);
    if (!_session.release(seatNumber)) return false;

    if (connectionId != null) {
      final connection = _connections[connectionId];
      if (connection != null) {
        connection.send(ErrorMessage.of(TableErrorCode.seatReleased).encode());
        unawaited(
          connection.close(
            code: TableCloseCode.normal,
            reason: 'released',
          ),
        );
        _forget(connectionId);
      }
    }

    _broadcastState();
    return true;
  }

  // -------------------------------------------------------------------------
  // Broadcasts
  // -------------------------------------------------------------------------

  void _sendError(TableConnection connection, TableErrorCode code) {
    connection.send(ErrorMessage.of(code).encode());
  }

  /// The set of seats changed: someone joined, left or was released.
  void _broadcastState() {
    if (_closed) return;
    final current = state;
    final frame = StateMessage(
      capacity: capacity,
      phase: current.phase,
      seats: current.seats,
    ).encode();
    for (final id in _connections.keys.toList()) {
      if (_session.seatNumberForConnection(id) == null) continue;
      _connections[id]?.send(frame);
    }
    _publish();
  }

  /// Only one seat's phone came or went; the seat list itself is unchanged.
  void _broadcastPresence(int seatNumber) {
    if (_closed) return;
    final seat = _session.seatAt(seatNumber);
    if (seat == null) return;
    final frame = PresenceMessage(
      seat: seatNumber,
      connected: seat.connected,
    ).encode();
    for (final id in _connections.keys.toList()) {
      if (_session.seatNumberForConnection(id) == null) continue;
      _connections[id]?.send(frame);
    }
    _publish();
  }

  void _publish() {
    if (_closed) return;
    _states.add(state);
  }

  void _drop(String connectionId) {
    _forget(connectionId);
    final seat = _session.disconnect(connectionId);
    if (seat != null) _broadcastPresence(seat);
  }

  /// Forgets a connection without touching the session.
  ///
  /// Used when the board itself closed the socket, so the close handler must not
  /// mistake it for a phone that vanished and mark the seat away.
  void _forget(String connectionId) {
    _subscriptions.remove(connectionId)?.cancel();
    _connections.remove(connectionId);
    _attachedAt.remove(connectionId);
  }
}
