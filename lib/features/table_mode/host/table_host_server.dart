import 'dart:async';
import 'dart:io';

import '../io/local_address.dart';
import '../io/websocket_table_connection.dart';
import '../protocol/table_connection.dart';
import '../protocol/table_protocol.dart';
import 'table_host_transport.dart';

/// Why the board could not open a room. Each one is a sentence on the screen,
/// not a stack trace.
enum HostBindFailure {
  /// No Wi-Fi address: the device is on no network a phone could reach.
  noNetwork,

  /// Every candidate port is taken. Vanishingly unlikely, but not a crash.
  noPort,

  /// The platform refused to listen at all.
  refused;

  String get message => switch (this) {
    noNetwork => 'This device is not on a Wi-Fi network.',
    noPort => 'This device could not open a port for the room.',
    refused => 'The room could not be opened on this device.',
  };
}

/// A bound room: the address and port a phone can actually use.
class HostBinding {
  const HostBinding({required this.address, required this.port});

  final String address;
  final int port;
}

/// The board's socket layer: bind, accept, upgrade.
///
/// Everything above this file works on [TableConnection]s, so the room's rules
/// never see `dart:io`. One route is served — `GET /table` with an upgrade
/// header. Anything else is a 404, because there is nothing else to serve in
/// Phase 1.
class IoTableHostServer implements TableHostTransport {
  IoTableHostServer({
    this.endpointPath = TableProtocol.endpointPath,
    Future<String?> Function()? findAddress,
    List<int>? ports,
  }) : _findAddress = findAddress ?? findLocalIpv4,
       _ports = ports ?? TableProtocol.candidatePorts;

  final String endpointPath;

  /// Where the advertised address comes from. Overridden by the loopback test,
  /// which must not depend on the machine having a Wi-Fi card.
  final Future<String?> Function() _findAddress;

  /// Which ports to try. Overridden by the loopback test with `[0]`, so it
  /// never collides with a real board.
  final List<int> _ports;

  HttpServer? _server;
  final StreamController<TableConnection> _connections =
      StreamController<TableConnection>.broadcast();

  /// Every socket this server accepted, so [close] can end them even if the
  /// room above has already forgotten one.
  final List<TableConnection> _open = [];
  bool _closed = false;

  /// Accepted sockets, in the order they arrived.
  @override
  Stream<TableConnection> get connections => _connections.stream;

  bool get isRunning => _server != null;

  /// Binds the first free candidate port, or reports why it could not.
  ///
  /// Returns the address the board should print: the one a phone on the same
  /// network can reach, not `0.0.0.0`.
  @override
  Future<(HostBinding?, HostBindFailure?)> bind() async {
    if (_closed) return (null, HostBindFailure.refused);

    final address = await _findAddress();
    if (address == null) return (null, HostBindFailure.noNetwork);

    for (final port in _ports) {
      try {
        final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
        _server = server;
        server.listen(
          _onRequest,
          onError: (Object _) {
            // A single bad request must not take the room down.
          },
        );
        // `server.port` rather than `port`: a test asks for 0 and gets a real
        // ephemeral port back, and the QR must carry the one that works.
        return (HostBinding(address: address, port: server.port), null);
      } on SocketException {
        // Taken. Try the next one; the board prints whichever it got.
        continue;
      } on Object {
        return (null, HostBindFailure.refused);
      }
    }

    return (null, HostBindFailure.noPort);
  }

  Future<void> _onRequest(HttpRequest request) async {
    if (request.uri.path != endpointPath) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    try {
      final socket = await WebSocketTransformer.upgrade(request);
      if (_closed) {
        await socket.close(
          TableCloseCode.goingAway,
          'room closed',
        );
        return;
      }
      final connection = WebSocketTableConnection(socket);
      _open.add(connection);
      _connections.add(connection);
    } on Object {
      // The client hung up mid-handshake. Nothing to reply to.
    }
  }

  /// Closes the listener and every accepted socket.
  ///
  /// A phone still connected gets a 1001 so it shows "the board closed the
  /// room" instead of retrying a room that no longer exists.
  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;

    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }

    final open = _open.toList();
    _open.clear();
    for (final connection in open) {
      await connection.close(
        code: TableCloseCode.goingAway,
        reason: 'room closed',
      );
    }

    await _connections.close();
  }
}
