import '../protocol/table_connection.dart';
import 'table_host_server.dart';

/// What the board needs from a socket layer, and nothing more.
///
/// `IoTableHostServer` is the production implementation; a test overrides the
/// provider with one that hands out in-memory connections. The controller never
/// sees `HttpServer`, so no widget test ever binds a port.
abstract interface class TableHostTransport {
  /// Sockets as they are accepted.
  Stream<TableConnection> get connections;

  /// Opens the room, or says why it could not.
  Future<(HostBinding?, HostBindFailure?)> bind();

  /// Closes the listener and every accepted socket.
  Future<void> close();
}
