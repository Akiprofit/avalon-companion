import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../protocol/table_announcement.dart';
import '../protocol/table_protocol.dart';
import 'table_announcer_control.dart';

/// Shouts the room's existence onto the LAN, once every
/// [TableProtocol.announceInterval].
///
/// This is what makes a typed six-character code work: the code names a room,
/// so the board has to say where the room is. It is also the part most likely to
/// be blocked by a venue router, which is why the QR carries the address
/// directly and the join screen accepts a typed address too.
class TableAnnouncer implements TableAnnouncerControl {
  TableAnnouncer({
    required this.announcement,
    required this.port,
    this.target = '255.255.255.255',
    this.interval = TableProtocol.announceInterval,
  });

  final TableAnnouncement announcement;

  /// The UDP port to shout at. The phone listens on the same numbers the board
  /// might have bound, so this is normally the board's own TCP port.
  final int port;

  final String target;
  final Duration interval;

  RawDatagramSocket? _socket;
  Timer? _timer;

  bool get isRunning => _timer != null;

  /// Returns false when the datagram socket could not be opened, which is not
  /// fatal: the QR and the typed address still work.
  @override
  Future<bool> start() async {
    if (_timer != null) return true;
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      socket.broadcastEnabled = true;
      _socket = socket;
    } on Object {
      return false;
    }

    _announce();
    _timer = Timer.periodic(interval, (_) => _announce());
    return true;
  }

  void _announce() {
    final socket = _socket;
    if (socket == null) return;
    try {
      socket.send(
        utf8.encode(announcement.encode()),
        InternetAddress(target),
        port,
      );
    } on Object {
      // A network that refuses broadcast is a network the QR path still serves.
    }
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
  }
}
