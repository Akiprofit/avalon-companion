import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../model/room_code.dart';
import '../protocol/table_announcement.dart';
import '../protocol/table_invite.dart';
import '../protocol/table_protocol.dart';

/// Finds the board behind a typed code.
///
/// Listens on every port the board might have bound, for up to [window]. The
/// first announcement whose code matches wins, and its source address — not the
/// name inside the datagram — is what the phone connects to.
///
/// This is an optimisation, not the only path: a QR carries the address, and the
/// join screen accepts a typed address for networks that drop broadcast.
class TableDiscovery {
  TableDiscovery({
    List<int>? ports,
    this.window = TableProtocol.discoveryWindow,
  }) : ports = ports ?? TableProtocol.candidatePorts;

  final List<int> ports;
  final Duration window;

  final List<RawDatagramSocket> _sockets = [];
  Timer? _timer;
  Completer<TableInvite?>? _pending;
  bool _finished = false;

  /// Resolves to the board's invite, or null when nothing answered in time.
  Future<TableInvite?> find(String code) async {
    final wanted = RoomCode.normalise(code);
    if (wanted == null) return null;

    await cancel();

    final completer = Completer<TableInvite?>();
    _pending = completer;
    _finished = false;

    var bound = 0;
    for (final port in ports) {
      try {
        final socket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          port,
          reuseAddress: true,
        );
        _sockets.add(socket);
        bound++;
        socket.listen((event) => _onEvent(socket, event, wanted));
      } on Object {
        // Port taken by something else, or refused. Other ports may still work.
        continue;
      }
    }

    if (bound == 0) {
      _finish(null);
      return completer.future;
    }

    _timer = Timer(window, () => _finish(null));
    return completer.future;
  }

  void _onEvent(RawDatagramSocket socket, RawSocketEvent event, String wanted) {
    if (event != RawSocketEvent.read || _finished) return;
    final datagram = socket.receive();
    if (datagram == null) return;

    final announcement = TableAnnouncement.parse(
      utf8.decode(datagram.data, allowMalformed: true),
    );
    if (announcement == null || announcement.code != wanted) return;

    _finish(
      TableInvite(
        code: wanted,
        host: datagram.address.address,
        port: announcement.port,
      ),
    );
  }

  /// Stops listening and resolves any search in flight with null.
  Future<void> cancel() async {
    _finish(null);
  }

  void _finish(TableInvite? invite) {
    if (_finished && _pending == null) return;
    _finished = true;

    _timer?.cancel();
    _timer = null;

    final sockets = _sockets.toList();
    _sockets.clear();
    for (final socket in sockets) {
      socket.close();
    }

    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(invite);
  }
}
