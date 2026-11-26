import 'dart:convert';

import '../model/room_state.dart';
import '../model/seat.dart';
import 'table_protocol.dart';

/// One frame, in either direction.
///
/// The sealed hierarchy is the message list: adding a type means adding a class
/// here, and the decoder's `switch` stops compiling until it is handled.
sealed class TableMessage {
  const TableMessage();

  String get type;

  Map<String, Object?> toJson();

  String encode() => jsonEncode(toJson());
}

// ---------------------------------------------------------------------------
// Phone → board
// ---------------------------------------------------------------------------

/// "Seat me", or "seat me again as the same player".
final class HelloMessage extends TableMessage {
  const HelloMessage({
    required this.code,
    required this.name,
    this.token,
  });

  /// The code the player typed or scanned. The board checks it, so a phone that
  /// found the wrong board is told rather than seated.
  final String code;

  final String name;

  /// Present only when this phone has held a seat before.
  final String? token;

  @override
  String get type => 'hello';

  @override
  Map<String, Object?> toJson() => {
    'v': TableProtocol.version,
    'type': type,
    'code': code,
    'name': name,
    if (token != null) 'token': token,
  };
}

/// Keepalive, and the round-trip measurement that goes with it.
final class PingMessage extends TableMessage {
  const PingMessage({required this.t});

  /// Milliseconds since the epoch, echoed back untouched.
  final int t;

  @override
  String get type => 'ping';

  @override
  Map<String, Object?> toJson() => {
    'v': TableProtocol.version,
    'type': type,
    't': t,
  };
}

/// A clean exit: release the seat now, rather than after the watchdog.
final class LeaveMessage extends TableMessage {
  const LeaveMessage();

  @override
  String get type => 'leave';

  @override
  Map<String, Object?> toJson() => {
    'v': TableProtocol.version,
    'type': type,
  };
}

// ---------------------------------------------------------------------------
// Board → phone
// ---------------------------------------------------------------------------

/// Identity and the first snapshot, in one frame.
final class WelcomeMessage extends TableMessage {
  const WelcomeMessage({
    required this.seat,
    required this.token,
    required this.code,
    required this.capacity,
    required this.phase,
    required this.seats,
  });

  final int seat;

  /// The phone's proof of seat, for a reconnect. It goes to this phone only.
  final String token;

  final String code;
  final int capacity;
  final RoomPhase phase;
  final List<Seat> seats;

  @override
  String get type => 'welcome';

  @override
  Map<String, Object?> toJson() => {
    'v': TableProtocol.version,
    'type': type,
    'seat': seat,
    'token': token,
    'code': code,
    'capacity': capacity,
    'phase': phase.wire,
    'seats': [for (final seat in seats) seat.toJson()],
  };
}

/// The room changed: someone joined, left or was released.
final class StateMessage extends TableMessage {
  const StateMessage({
    required this.capacity,
    required this.phase,
    required this.seats,
  });

  final int capacity;
  final RoomPhase phase;
  final List<Seat> seats;

  @override
  String get type => 'state';

  @override
  Map<String, Object?> toJson() => {
    'v': TableProtocol.version,
    'type': type,
    'capacity': capacity,
    'phase': phase.wire,
    'seats': [for (final seat in seats) seat.toJson()],
  };
}

/// One seat's phone came back or went away. The seat list itself is unchanged.
final class PresenceMessage extends TableMessage {
  const PresenceMessage({required this.seat, required this.connected});

  final int seat;
  final bool connected;

  @override
  String get type => 'presence';

  @override
  Map<String, Object?> toJson() => {
    'v': TableProtocol.version,
    'type': type,
    'seat': seat,
    'connected': connected,
  };
}

/// The echo of a [PingMessage].
final class PongMessage extends TableMessage {
  const PongMessage({required this.t});

  final int t;

  @override
  String get type => 'pong';

  @override
  Map<String, Object?> toJson() => {
    'v': TableProtocol.version,
    'type': type,
    't': t,
  };
}

/// A refusal. [message] is shown to the player as-is.
final class ErrorMessage extends TableMessage {
  const ErrorMessage({required this.code, required this.message});

  ErrorMessage.of(TableErrorCode code) : this(code: code, message: code.message);

  final TableErrorCode code;
  final String message;

  @override
  String get type => 'error';

  @override
  Map<String, Object?> toJson() => {
    'v': TableProtocol.version,
    'type': type,
    'code': code.wire,
    'message': message,
  };
}

// ---------------------------------------------------------------------------
// Decoding
// ---------------------------------------------------------------------------

/// Either a frame or the reason it could not be read.
sealed class TableDecodeResult {
  const TableDecodeResult();
}

final class TableDecoded extends TableDecodeResult {
  const TableDecoded(this.message);

  final TableMessage message;
}

final class TableDecodeFailure extends TableDecodeResult {
  const TableDecodeFailure(this.code, this.reason);

  final TableErrorCode code;

  /// For the host's own diagnostics. Never sent to a phone.
  final String reason;
}

/// Reads one frame. Never throws: a bad frame is a value, because a phone with
/// a bug must not be able to take the board down.
TableDecodeResult decodeTableFrame(String raw) {
  if (raw.length > TableProtocol.maxFrameBytes) {
    return const TableDecodeFailure(
      TableErrorCode.badMessage,
      'frame too large',
    );
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (error) {
    return TableDecodeFailure(TableErrorCode.badMessage, 'not json: $error');
  }
  if (decoded is! Map) {
    return const TableDecodeFailure(
      TableErrorCode.badMessage,
      'frame is not an object',
    );
  }
  final map = <String, Object?>{
    for (final entry in decoded.entries) '${entry.key}': entry.value,
  };

  if (!map.containsKey('v')) {
    return const TableDecodeFailure(TableErrorCode.badMessage, 'missing v');
  }
  if (map['v'] != TableProtocol.version) {
    return TableDecodeFailure(
      TableErrorCode.version,
      'version ${map['v']}',
    );
  }

  final type = map['type'];
  if (type is! String) {
    return const TableDecodeFailure(TableErrorCode.badMessage, 'missing type');
  }
  if (!_knownTypes.contains(type)) {
    return TableDecodeFailure(TableErrorCode.unknownType, 'unknown type $type');
  }

  try {
    return TableDecoded(_messageOf(type, map));
  } on FormatException catch (error) {
    return TableDecodeFailure(TableErrorCode.badMessage, error.message);
  }
}

/// The types this version understands. Anything else is refused as
/// `unknown_type` rather than as a malformed frame.
const Set<String> _knownTypes = {
  'hello',
  'ping',
  'leave',
  'welcome',
  'state',
  'presence',
  'pong',
  'error',
};

TableMessage _messageOf(String type, Map<String, Object?> map) {
  switch (type) {
    case 'hello':
      return HelloMessage(
        code: _string(map, 'code'),
        name: _string(map, 'name'),
        token: _optionalString(map, 'token'),
      );
    case 'ping':
      return PingMessage(t: _int(map, 't'));
    case 'leave':
      return const LeaveMessage();
    case 'welcome':
      return WelcomeMessage(
        seat: _int(map, 'seat'),
        token: _string(map, 'token'),
        code: _string(map, 'code'),
        capacity: _int(map, 'capacity'),
        phase: RoomPhase.fromWire(_string(map, 'phase')),
        seats: _seats(map),
      );
    case 'state':
      return StateMessage(
        capacity: _int(map, 'capacity'),
        phase: RoomPhase.fromWire(_string(map, 'phase')),
        seats: _seats(map),
      );
    case 'presence':
      return PresenceMessage(
        seat: _int(map, 'seat'),
        connected: _bool(map, 'connected'),
      );
    case 'pong':
      return PongMessage(t: _int(map, 't'));
    case 'error':
      final code = TableErrorCode.fromWire(_string(map, 'code'));
      if (code == null) {
        throw FormatException('unknown error code ${map['code']}');
      }
      return ErrorMessage(code: code, message: _string(map, 'message'));
    default:
      throw FormatException('unknown type $type');
  }
}

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String) throw FormatException('missing $key');
  return value;
}

String? _optionalString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key is not a string');
  return value;
}

int _int(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('missing $key');
  return value;
}

bool _bool(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! bool) throw FormatException('missing $key');
  return value;
}

List<Seat> _seats(Map<String, Object?> map) {
  final value = map['seats'];
  if (value is! List) throw const FormatException('missing seats');
  final seats = <Seat>[];
  for (final item in value) {
    if (item is! Map) throw const FormatException('seat is not an object');
    final entry = <String, Object?>{
      for (final pair in item.entries) '${pair.key}': pair.value,
    };
    seats.add(
      Seat(
        number: _int(entry, 'seat'),
        name: _string(entry, 'name'),
        connected: _bool(entry, 'connected'),
      ),
    );
  }
  return seats;
}
