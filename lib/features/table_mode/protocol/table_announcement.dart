import 'table_protocol.dart';

/// The datagram the board shouts onto the LAN so a typed code can find it.
///
/// A six-character code names a room, not an address, so the board has to say
/// where it is. One line, one datagram every [TableProtocol.announceInterval],
/// no dependency and no multicast group for a venue router to drop.
class TableAnnouncement {
  const TableAnnouncement({
    required this.code,
    required this.port,
    required this.boardName,
  });

  final String code;

  /// The TCP port the board actually bound, which may not be 8787.
  final int port;

  /// What the board calls itself, so two boards on one network are told apart
  /// by a human rather than by an IP address.
  final String boardName;

  /// `AVALON1|7K3QF9|8787|Avalon board`.
  String encode() {
    final safeName = boardName.replaceAll('|', ' ').trim();
    return '${TableProtocol.discoveryMagic}|$code|$port|$safeName';
  }

  /// Null for anything that is not one of ours: a stray datagram, a future
  /// version, a different app. Discovery ignores those rather than guessing.
  static TableAnnouncement? parse(String raw) {
    final parts = raw.split('|');
    if (parts.length != 4) return null;
    if (parts[0] != TableProtocol.discoveryMagic) return null;

    final code = parts[1];
    if (code.length != 6) return null;

    final port = int.tryParse(parts[2]);
    if (port == null || port < 1 || port > 65535) return null;

    return TableAnnouncement(
      code: code,
      port: port,
      boardName: parts[3],
    );
  }
}
