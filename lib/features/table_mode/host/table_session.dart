import 'dart:math';

import '../model/room_state.dart';
import '../model/seat.dart';
import '../protocol/table_protocol.dart';

/// The answer to a `hello`.
sealed class JoinResult {
  const JoinResult();
}

final class JoinAccepted extends JoinResult {
  const JoinAccepted({
    required this.seat,
    required this.token,
    required this.isReturn,
    this.displacedConnection,
  });

  final int seat;
  final String token;

  /// True when this was a reconnect with a token, not a fresh seat.
  final bool isReturn;

  /// A live connection that held this seat and has just been displaced by a
  /// newer one. The room closes it, so two phones never share a seat.
  final String? displacedConnection;
}

final class JoinRejected extends JoinResult {
  const JoinRejected(this.code);

  final TableErrorCode code;
}

/// Seats, tokens and presence. The one object that knows which device holds
/// which seat.
///
/// It is not the room's state: the board renders [RoomState], a projection with
/// no tokens in it. Nothing here ever learns a character, and nothing here is
/// serialised.
class TableSession {
  TableSession({
    required this.code,
    this.capacity = TableProtocol.capacity,
    Random? random,
  }) : _random = random ?? Random.secure();

  final String code;
  final int capacity;
  final Random _random;

  /// Seat number → the seat and its private bookkeeping.
  final Map<int, _SeatRecord> _records = {};

  /// Device token → seat number.
  final Map<String, int> _seatByToken = {};

  /// Live connection → seat number.
  final Map<String, int> _seatByConnection = {};

  /// Tokens of seats the board released, so a returning phone is told what
  /// happened instead of being treated as a stranger with a taken name.
  final Map<String, int> _releasedTokens = {};

  static const int _releasedTokenMemory = 32;

  /// Seats in join order.
  List<Seat> get seats {
    final numbers = _records.keys.toList()..sort();
    return [for (final number in numbers) _records[number]!.seat];
  }

  bool get isFull => _records.length >= capacity;

  bool get isEmpty => _records.isEmpty;

  /// The lowest free seat number, or null when the room is full.
  int? get nextFreeSeat {
    for (var number = 1; number <= capacity; number++) {
      if (!_records.containsKey(number)) return number;
    }
    return null;
  }

  Seat? seatAt(int number) => _records[number]?.seat;

  /// The seat this live connection holds, if any.
  int? seatNumberForConnection(String connectionId) =>
      _seatByConnection[connectionId];

  /// The token for a seat. Host-side only; never rendered, never broadcast.
  String? tokenForSeat(int seat) => _records[seat]?.token;

  /// The live connection holding a seat, or null when its phone is away.
  /// Host-side only: the board closes this socket when the MC releases a seat.
  String? connectionForSeat(int seat) => _records[seat]?.connectionId;

  RoomState roomState({
    required String address,
    required int port,
    RoomPhase phase = RoomPhase.lobby,
  }) {
    return RoomState(
      code: code,
      address: address,
      port: port,
      capacity: capacity,
      seats: seats,
      phase: phase,
    );
  }

  /// Seats a phone, or returns it to the seat its token already owns.
  ///
  /// A valid token always wins: same seat, same name, connected again. A token
  /// that is missing, malformed or unknown is treated as no token at all — a
  /// corrupted token must never lock a player out, and it can never match a
  /// real seat.
  JoinResult join({
    required String connectionId,
    required String rawName,
    String? token,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();

    if (_seatByConnection.containsKey(connectionId)) {
      return const JoinRejected(TableErrorCode.alreadySeated);
    }

    if (isDeviceToken(token)) {
      final seatNumber = _seatByToken[token];
      if (seatNumber != null) {
        return _reclaim(
          connectionId: connectionId,
          seatNumber: seatNumber,
          token: token!,
          at: at,
        );
      }
      if (_releasedTokens.containsKey(token)) {
        return const JoinRejected(TableErrorCode.seatReleased);
      }
    }

    return _seatFresh(connectionId: connectionId, rawName: rawName, at: at);
  }

  JoinResult _reclaim({
    required String connectionId,
    required int seatNumber,
    required String token,
    required DateTime at,
  }) {
    final record = _records[seatNumber]!;
    final previous = record.connectionId;

    // The newest connection wins. The old one is closed by the room; dropping
    // its mapping here means its close does not mark the seat away afterwards.
    if (previous != null && previous != connectionId) {
      _seatByConnection.remove(previous);
    }

    _records[seatNumber] = record.copyWith(
      seat: record.seat.copyWith(connected: true),
      connectionId: connectionId,
      lastSeenAt: at,
    );
    _seatByConnection[connectionId] = seatNumber;

    return JoinAccepted(
      seat: seatNumber,
      token: token,
      isReturn: true,
      displacedConnection: previous != null && previous != connectionId
          ? previous
          : null,
    );
  }

  JoinResult _seatFresh({
    required String connectionId,
    required String rawName,
    required DateTime at,
  }) {
    final name = normalisePlayerName(rawName);
    if (name == null) return const JoinRejected(TableErrorCode.nameInvalid);

    final taken = _records.values.any(
      (record) => record.seat.name.toLowerCase() == name.toLowerCase(),
    );
    if (taken) return const JoinRejected(TableErrorCode.nameTaken);

    final seatNumber = nextFreeSeat;
    if (seatNumber == null) return const JoinRejected(TableErrorCode.roomFull);

    final token = _newToken();
    _records[seatNumber] = _SeatRecord(
      seat: Seat(number: seatNumber, name: name, connected: true),
      token: token,
      connectionId: connectionId,
      lastSeenAt: at,
    );
    _seatByToken[token] = seatNumber;
    _seatByConnection[connectionId] = seatNumber;

    return JoinAccepted(seat: seatNumber, token: token, isReturn: false);
  }

  /// A socket went away. The seat is kept, so a reconnect finds it.
  ///
  /// Returns the seat number whose presence changed, or null when this
  /// connection held no seat (or had already been displaced).
  int? disconnect(String connectionId) {
    final seatNumber = _seatByConnection.remove(connectionId);
    if (seatNumber == null) return null;
    final record = _records[seatNumber];
    if (record == null || record.connectionId != connectionId) return null;

    _records[seatNumber] = record.copyWith(
      seat: record.seat.copyWith(connected: false),
      clearConnection: true,
    );
    return seatNumber;
  }

  /// The player tapped "Leave the table": the seat is gone, not merely away.
  int? releaseForConnection(String connectionId) {
    final seatNumber = _seatByConnection[connectionId];
    if (seatNumber == null) return null;
    return release(seatNumber) ? seatNumber : null;
  }

  /// Removes a seat outright — the player left, or the board released a phone
  /// that is not coming back.
  bool release(int seatNumber) {
    final record = _records.remove(seatNumber);
    if (record == null) return false;

    _seatByToken.remove(record.token);
    final connection = record.connectionId;
    if (connection != null) _seatByConnection.remove(connection);

    // Remember the token so a returning phone is told the seat was released.
    _releasedTokens[record.token] = seatNumber;
    while (_releasedTokens.length > _releasedTokenMemory) {
      _releasedTokens.remove(_releasedTokens.keys.first);
    }
    return true;
  }

  /// Records that the phone is still there.
  int? touch(String connectionId, {DateTime? now}) {
    final seatNumber = _seatByConnection[connectionId];
    if (seatNumber == null) return null;
    final record = _records[seatNumber];
    if (record == null) return null;
    _records[seatNumber] = record.copyWith(lastSeenAt: now ?? DateTime.now());
    return seatNumber;
  }

  /// Connections whose seat has been silent for [timeout].
  List<String> silentConnections(DateTime now, Duration timeout) {
    final silent = <String>[];
    for (final record in _records.values) {
      final connection = record.connectionId;
      if (connection == null) continue;
      if (now.difference(record.lastSeenAt) >= timeout) silent.add(connection);
    }
    return silent;
  }

  String _newToken() {
    final buffer = StringBuffer();
    for (var i = 0; i < TableProtocol.tokenBytes; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

/// A seat plus the facts only the host may know.
class _SeatRecord {
  const _SeatRecord({
    required this.seat,
    required this.token,
    required this.connectionId,
    required this.lastSeenAt,
  });

  final Seat seat;
  final String token;
  final String? connectionId;
  final DateTime lastSeenAt;

  _SeatRecord copyWith({
    Seat? seat,
    String? connectionId,
    bool clearConnection = false,
    DateTime? lastSeenAt,
  }) {
    return _SeatRecord(
      seat: seat ?? this.seat,
      token: token,
      connectionId: clearConnection ? null : (connectionId ?? this.connectionId),
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
