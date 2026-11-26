import 'dart:async';
import 'dart:io';

import '../protocol/table_connection.dart';

/// A [TableConnection] over a real `dart:io` WebSocket.
///
/// This is the only place a socket becomes a frame. Both the board and the
/// phone use it, so the protocol above sees exactly the same interface in
/// production as it does in a test with in-memory connections.
class WebSocketTableConnection implements TableConnection {
  WebSocketTableConnection(this._socket, {String? id})
    : id = id ?? 'ws-${_counter++}';

  static int _counter = 0;

  final WebSocket _socket;

  @override
  final String id;

  @override
  Stream<String> get incoming =>
      _socket.where((event) => event is String).cast<String>();

  @override
  int? get closeCode => _socket.closeCode;

  @override
  void send(String frame) {
    if (_socket.readyState != WebSocket.open) return;
    try {
      _socket.add(frame);
    } on Object {
      // The peer went away between the check and the add. A board mid-broadcast
      // must not throw because one phone dropped; the close handler will mark
      // that seat away a moment later.
    }
  }

  @override
  Future<void> close({int? code, String? reason}) async {
    if (_socket.readyState == WebSocket.closed) return;
    try {
      await _socket.close(
        code ?? TableCloseCode.normal,
        reason,
      );
    } on Object {
      // Already gone. Closing a closed socket is not an error worth surfacing.
    }
  }
}
