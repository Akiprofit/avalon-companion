import 'table_protocol.dart';

/// One socket, seen as a stream of frames.
///
/// Everything above this interface is pure Dart: the host session, the room
/// state machine and the client never touch `dart:io`. That is what lets the
/// whole protocol be tested on in-memory connections, and driven from a PC
/// probe against a real board, without a socket in either case.
abstract interface class TableConnection {
  /// Unique for the life of the room. The host keys seats by it, never by the
  /// socket object.
  String get id;

  /// Frames as they arrive. Closes when the peer goes away.
  Stream<String> get incoming;

  /// The WebSocket close code once the socket is closed, or null.
  ///
  /// The client uses it to tell "the board closed the room" (1000/1001) from
  /// "the Wi-Fi went away" (anything else, or null).
  int? get closeCode;

  /// Sends one frame. Silently does nothing once closed: a phone that vanished
  /// mid-broadcast must not throw inside the host's loop.
  void send(String frame);

  Future<void> close({int? code, String? reason});
}

/// The close codes the room uses, spelled out so neither side guesses.
abstract final class TableCloseCode {
  /// A clean exit: the player left, or the room was closed on purpose.
  static const int normal = 1000;

  /// The board is going away: it closed the room or dropped a silent seat.
  static const int goingAway = 1001;

  /// The peer sent something the protocol cannot accept.
  static const int policy = 1008;

  /// A frame larger than [TableProtocol.maxFrameBytes].
  static const int tooLarge = 1009;
}
