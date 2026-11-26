import 'dart:io';

import '../io/websocket_table_connection.dart';
import '../protocol/table_connection.dart';

/// Opens one real socket to the board.
///
/// The whole of the phone's `dart:io` surface: everything above this is pure
/// Dart and runs against an in-memory connection in tests. The caller applies
/// the five-second connect timeout; a refused or unreachable board throws, and
/// `TableClient` turns that into "lost, try again".
Future<TableConnection> connectTableSocket(Uri uri) async {
  final socket = await WebSocket.connect(uri.toString());
  return WebSocketTableConnection(socket);
}
