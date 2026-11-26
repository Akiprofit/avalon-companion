import 'dart:async';

import '../model/room_state.dart';
import '../model/seat.dart';
import '../protocol/table_connection.dart';
import '../protocol/table_invite.dart';
import '../protocol/table_message.dart';
import '../protocol/table_protocol.dart';

/// How a phone opens a socket. Injected so tests — and the PC probe — never
/// need a real one.
typedef TableConnect = Future<TableConnection> Function(Uri uri);

/// What a phone is doing right now.
sealed class TableClientState {
  const TableClientState();
}

final class TableClientIdle extends TableClientState {
  const TableClientIdle();
}

final class TableClientConnecting extends TableClientState {
  const TableClientConnecting(this.attempt);

  final int attempt;
}

/// Seated, with the room's public state as of the last frame.
final class TableClientSeated extends TableClientState {
  const TableClientSeated({
    required this.seat,
    required this.token,
    required this.capacity,
    required this.seats,
    required this.phase,
  });

  final int seat;

  /// The device's proof of seat. Kept in memory only (docs/table-mode-plan.md §4).
  final String token;

  final int capacity;
  final List<Seat> seats;
  final RoomPhase phase;
}

/// The board refused, and will refuse again on the same terms.
final class TableClientRejected extends TableClientState {
  const TableClientRejected(this.code, this.message);

  final TableErrorCode code;
  final String message;
}

/// The socket went away. [canRetry] is false once the reconnect window is spent.
final class TableClientLost extends TableClientState {
  const TableClientLost({required this.attempt, required this.canRetry});

  final int attempt;
  final bool canRetry;
}

/// The board closed the room on purpose. Retrying would be pointless.
final class TableClientClosed extends TableClientState {
  const TableClientClosed();
}

/// A phone's side of the protocol.
///
/// It owns no timers: the controller decides when to ping and when to try
/// again, using [retryDelay]. That is what keeps a unit test free of pending
/// futures and lets the whole reconnect story be driven by hand.
class TableClient {
  TableClient({
    required this.invite,
    required String name,
    required this.connect,
    DateTime Function()? clock,
    this.reconnectWindow = TableProtocol.reconnectWindow,
  }) : _playerName = name,
       _clock = clock ?? DateTime.now;

  final TableInvite invite;
  final TableConnect connect;
  final Duration reconnectWindow;
  final DateTime Function() _clock;

  String _playerName;
  String? _token;
  int _attempt = 0;
  DateTime? _lostSince;
  bool _opening = false;
  bool _disposed = false;

  TableConnection? _connection;
  StreamSubscription<String>? _subscription;
  Completer<TableClientState>? _pendingWelcome;

  final StreamController<TableClientState> _states =
      StreamController<TableClientState>.broadcast();
  TableClientState _state = const TableClientIdle();

  Stream<TableClientState> get states => _states.stream;

  TableClientState get state => _state;

  String get name => _playerName;

  /// The token from the last seat, reused by every reconnect.
  String? get token => _token;

  /// Connect, say hello, and wait for the answer.
  ///
  /// Safe to call repeatedly: a call while a connection is opening or a seat is
  /// held does nothing.
  Future<void> open({String? name}) async {
    if (_disposed) return;
    if (name != null) _playerName = name;
    if (_opening) return;
    if (_state is TableClientSeated) return;

    _opening = true;
    try {
      _attempt++;
      _emit(TableClientConnecting(_attempt));

      final TableConnection connection;
      try {
        connection = await connect(
          invite.socketUri,
        ).timeout(TableProtocol.connectTimeout);
      } on Object {
        _fail();
        return;
      }

      if (_disposed) {
        unawaited(connection.close());
        return;
      }
      _connection = connection;

      final welcome = Completer<TableClientState>();
      _pendingWelcome = welcome;
      _subscription = connection.incoming.listen(
        (frame) => _onFrame(frame, welcome),
        onDone: () => _onDone(connection, welcome),
        onError: (Object _) => _onDone(connection, welcome),
        cancelOnError: false,
      );

      connection.send(
        HelloMessage(code: invite.code, name: _playerName, token: _token).encode(),
      );

      final TableClientState next;
      try {
        next = await welcome.future.timeout(TableProtocol.connectTimeout);
      } on TimeoutException {
        unawaited(
          connection.close(
            code: TableCloseCode.goingAway,
            reason: 'no welcome',
          ),
        );
        _fail();
        return;
      } finally {
        _pendingWelcome = null;
      }

      _emit(next);
      if (next is TableClientSeated) {
        _token = next.token;
        _attempt = 0;
        _lostSince = null;
      }
    } finally {
      _opening = false;
    }
  }

  /// Says "still here". The controller calls this on its ping interval.
  void ping() {
    final connection = _connection;
    if (connection == null) return;
    connection.send(
      PingMessage(t: _clock().millisecondsSinceEpoch).encode(),
    );
  }

  /// Clears the give-up state and tries again, e.g. from a Retry button.
  Future<void> retry() async {
    if (_disposed) return;
    _lostSince = null;
    _attempt = 0;
    await open();
  }

  /// How long to wait before the next attempt. The controller schedules it.
  static Duration retryDelay(int attempt) {
    final seconds = switch (attempt) {
      <= 1 => 1,
      2 => 2,
      3 => 3,
      _ => 5,
    };
    return Duration(seconds: seconds);
  }

  /// Tells the board this seat is done, then closes the socket.
  ///
  /// The frame is queued before the close, and TCP keeps the order, so the board
  /// releases the seat at once instead of waiting for the watchdog to mark it
  /// away. There is no delay here: a sleep would be a pending timer in a test.
  Future<void> leave() async {
    final connection = _connection;
    if (connection != null) {
      connection.send(const LeaveMessage().encode());
    }
    await dispose();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    final welcome = _pendingWelcome;
    _pendingWelcome = null;
    if (welcome != null && !welcome.isCompleted) {
      welcome.complete(const TableClientClosed());
    }

    // Close the socket before dropping the incoming subscription. Cancelling
    // the stream of a `dart:io` WebSocket tears the TCP socket down, which can
    // discard a leave frame still in flight; the board then sees an abnormal
    // close and keeps the seat until the watchdog marks it away.
    final connection = _connection;
    _connection = null;
    if (connection != null) {
      await connection.close(code: TableCloseCode.normal, reason: 'closed');
    }

    await _subscription?.cancel();
    _subscription = null;

    await _states.close();
  }

  // -------------------------------------------------------------------------
  // Frames
  // -------------------------------------------------------------------------

  void _onFrame(String frame, Completer<TableClientState> welcome) {
    final result = decodeTableFrame(frame);
    if (result is! TableDecoded) return;

    switch (result.message) {
      case WelcomeMessage(:final seat, :final token, :final capacity, :final seats, :final phase):
        final next = TableClientSeated(
          seat: seat,
          token: token,
          capacity: capacity,
          seats: seats,
          phase: phase,
        );
        if (welcome.isCompleted) {
          _token = token;
          _emit(next);
        } else {
          welcome.complete(next);
        }
      case StateMessage(:final capacity, :final seats, :final phase):
        final current = _state;
        if (current is TableClientSeated) {
          _emit(
            TableClientSeated(
              seat: current.seat,
              token: current.token,
              capacity: capacity,
              seats: seats,
              phase: phase,
            ),
          );
        }
      case PresenceMessage(:final seat, :final connected):
        final current = _state;
        if (current is TableClientSeated) {
          _emit(
            TableClientSeated(
              seat: current.seat,
              token: current.token,
              capacity: current.capacity,
              seats: [
                for (final other in current.seats)
                  other.number == seat
                      ? other.copyWith(connected: connected)
                      : other,
              ],
              phase: current.phase,
            ),
          );
        }
      case ErrorMessage(:final code, :final message):
        final next = TableClientRejected(code, message);
        if (welcome.isCompleted) {
          _emit(next);
        } else {
          welcome.complete(next);
        }
      case PongMessage():
      case PingMessage():
      case HelloMessage():
      case LeaveMessage():
        break;
    }
  }

  void _onDone(TableConnection connection, Completer<TableClientState> welcome) {
    if (_disposed) return;
    if (!identical(connection, _connection)) return;

    _connection = null;
    unawaited(_subscription?.cancel());
    _subscription = null;

    final closedByBoard =
        connection.closeCode == TableCloseCode.normal ||
        connection.closeCode == TableCloseCode.goingAway;

    if (_state is TableClientSeated) {
      if (closedByBoard) {
        _emit(const TableClientClosed());
      } else {
        _fail();
      }
      return;
    }

    if (welcome.isCompleted) return;
    welcome.complete(
      closedByBoard
          ? const TableClientClosed()
          : TableClientLost(attempt: _attempt, canRetry: _canRetry()),
    );
  }

  void _fail() {
    if (_disposed) return;
    _emit(TableClientLost(attempt: _attempt, canRetry: _canRetry()));
  }

  bool _canRetry() {
    _lostSince ??= _clock();
    return _clock().difference(_lostSince!) <= reconnectWindow;
  }

  void _emit(TableClientState next) {
    if (_disposed) return;
    _state = next;
    _states.add(next);
  }
}
