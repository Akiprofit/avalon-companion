/// Limits and timings shared by the board and the phones.
///
/// Every number here is a decision, not a default: they are the values the
/// plan was approved with (docs/table-mode-plan.md §3, §4).
abstract final class TableProtocol {
  /// Bumped only when a frame shape changes incompatibly.
  static const int version = 1;

  /// A 14-seat `welcome` is under 1 KB. Anything past this is a bug or an
  /// attempt to make the board parse something unbounded.
  static const int maxFrameBytes = 4096;

  /// The largest house table the engine already supports.
  static const int capacity = 14;

  static const int minNameLength = 1;
  static const int maxNameLength = 20;

  /// 16 random bytes, written as 32 hex characters.
  static const int tokenBytes = 16;

  static const int defaultPort = 8787;

  /// 8787, 8788, … so a port already in use is never a dead end.
  static const int portAttempts = 10;

  /// Every port the board may bind, and therefore every port a phone listens
  /// on for the announcement.
  static List<int> get candidatePorts => [
    for (var i = 0; i < portAttempts; i++) defaultPort + i,
  ];

  /// The WebSocket endpoint. One route, nothing else in Phase 1.
  static const String endpointPath = '/table';

  /// How often a seated phone says it is still there.
  static const Duration pingInterval = Duration(seconds: 10);

  /// A seat that has said nothing for this long is marked away and its socket
  /// closed. Three missed pings.
  static const Duration silentTimeout = Duration(seconds: 30);

  static const Duration connectTimeout = Duration(seconds: 5);

  /// How long a typed code is allowed to look for its board.
  static const Duration discoveryWindow = Duration(seconds: 6);

  /// How often the board announces itself on the LAN.
  static const Duration announceInterval = Duration(milliseconds: 1500);

  /// How long a phone keeps trying to get back into its seat before it offers
  /// the player a Retry button instead.
  static const Duration reconnectWindow = Duration(minutes: 2);

  /// The first word of the UDP announcement, so a stray datagram is ignored.
  static const String discoveryMagic = 'AVALON1';
}

/// Why the board refused something. The string is the wire value; the sentence
/// is what a player reads, so it lives here rather than in nine screens.
enum TableErrorCode {
  version('version', 'This phone and that board are different versions.'),
  badMessage('bad_message', 'The board could not read that message.'),
  unknownType('unknown_type', 'The board does not understand that request.'),
  roomNotFound('room_not_found', 'That code belongs to a different board.'),
  roomFull('room_full', 'The board has no free seat.'),
  nameTaken('name_taken', 'Someone at the table already used that name.'),
  nameInvalid('name_invalid', 'Use 1 to 20 characters.'),
  alreadySeated('already_seated', 'You already hold a seat on this connection.'),
  seatReleased('seat_released', 'That seat was released. Join again.');

  const TableErrorCode(this.wire, this.message);

  final String wire;
  final String message;

  static TableErrorCode? fromWire(String? value) {
    for (final code in values) {
      if (code.wire == value) return code;
    }
    return null;
  }

  /// Errors after which the phone should stop trying: the same connection will
  /// get the same answer. `roomFull` is not one — a seat can free up.
  bool get isTerminal =>
      this == version ||
      this == badMessage ||
      this == roomNotFound ||
      this == nameInvalid ||
      this == alreadySeated ||
      this == seatReleased;
}

/// A name as the table should see it, or null when it cannot be one.
///
/// Trimmed, 1 to 20 characters, no control characters. Names are not unique
/// across the app — only within one room, checked case-insensitively by the
/// session.
String? normalisePlayerName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.length < TableProtocol.minNameLength ||
      trimmed.length > TableProtocol.maxNameLength) {
    return null;
  }
  for (final unit in trimmed.codeUnits) {
    if (unit < 0x20 || unit == 0x7F) return null;
  }
  return trimmed;
}

/// Whether [value] is a device token: 32 lowercase hex characters.
bool isDeviceToken(String? value) {
  if (value == null || value.length != TableProtocol.tokenBytes * 2) {
    return false;
  }
  return RegExp(r'^[0-9a-f]+$').hasMatch(value);
}
