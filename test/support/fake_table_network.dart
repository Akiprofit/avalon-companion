import 'dart:async';

import 'package:avalon_companion/features/table_mode/host/table_announcer_control.dart';
import 'package:avalon_companion/features/table_mode/host/table_host_server.dart';
import 'package:avalon_companion/features/table_mode/host/table_host_transport.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_connection.dart';
import 'package:flutter_test/flutter_test.dart';

/// An async broadcast stream that holds frames until someone listens.
///
/// A single-subscription controller is the wrong shape here: cancelling its
/// only subscription from inside a widget test never completes, so a room
/// teardown would hang forever. A broadcast controller cancels and closes
/// cleanly. Frames sent before the room subscribes are buffered and replayed
/// on the first listen, which keeps the room's "answer the phone" order.
class BufferedBroadcast<T> {
  final List<T> _pending = [];
  late final StreamController<T> _controller = StreamController<T>.broadcast(
    onListen: _flush,
  );

  Stream<T> get stream => _controller.stream;

  void add(T value) {
    if (_controller.hasListener) {
      _controller.add(value);
    } else {
      _pending.add(value);
    }
  }

  void _flush() {
    if (_pending.isEmpty) return;
    final replay = List<T>.of(_pending);
    _pending.clear();
    for (final value in replay) {
      _controller.add(value);
    }
  }

  Future<void> close() => _controller.close();
}

/// One end of an in-memory socket.
///
/// Frames sent here arrive on the peer's [incoming] stream, in order, and a
/// close travels both ways. There is no timer and no port, so a room test can
/// run a whole lobby without touching the network.
class FakeTableConnection implements TableConnection {
  FakeTableConnection(this.id);

  @override
  final String id;

  final BufferedBroadcast<String> _incoming = BufferedBroadcast<String>();

  /// Every frame this end sent, oldest first. Assertions read this.
  final List<String> sent = [];

  /// Every frame this end received, oldest first.
  ///
  /// The room answers from the host end, so a test that asks "what did the
  /// phone see?" reads this and not [sent].
  final List<String> received = [];

  @override
  int? closeCode;

  FakeTableConnection? _peer;
  bool _closed = false;

  bool get isClosed => _closed;

  @override
  Stream<String> get incoming => _incoming.stream;

  @override
  void send(String frame) {
    if (_closed) return;
    sent.add(frame);
    _peer?._deliver(frame);
  }

  @override
  Future<void> close({int? code, String? reason}) async {
    if (_closed) return;
    _closed = true;
    closeCode = code;
    // Closing is not awaited: the peer must hear about the close even when
    // this end has no listener left. Tests call `settle()` to let the done
    // event arrive.
    unawaited(_incoming.close());
    _peer?._peerClosed(code);
  }

  void _deliver(String frame) {
    if (_closed) return;
    received.add(frame);
    _incoming.add(frame);
  }

  /// The peer closed: this end sees the same code and its stream ends.
  void _peerClosed(int? code) {
    if (_closed) return;
    _closed = true;
    closeCode = code;
    unawaited(_incoming.close());
  }

  /// Drops the socket without a close frame, the way a phone leaving Wi-Fi
  /// coverage does: the stream simply ends.
  Future<void> vanish() async {
    if (_closed) return;
    _closed = true;
    unawaited(_incoming.close());
    _peer?._peerClosed(null);
  }
}

/// Two ends of one in-memory socket, named for who is holding them.
///
/// Ids are unique by default: the room keys seats by connection id, so two
/// pairs with the same id would look like one phone reconnecting.
class FakeSocketPair {
  FakeSocketPair({String? hostId, String? phoneId})
    : host = FakeTableConnection(hostId ?? 'host-${_counter + 1}'),
      phone = FakeTableConnection(phoneId ?? 'phone-${_counter + 1}') {
    _counter++;
    host._peer = phone;
    phone._peer = host;
  }

  static int _counter = 0;

  final FakeTableConnection host;
  final FakeTableConnection phone;
}

/// A board transport that never binds a port.
///
/// [accept] hands the board a new socket and returns the phone's end, which is
/// exactly what a real accept does minus the handshake.
class FakeTableHostTransport implements TableHostTransport {
  FakeTableHostTransport({
    this.address = '192.168.43.1',
    this.port = 8787,
    this.failure,
  });

  final String address;
  final int port;

  /// When set, [bind] fails with this and no room opens.
  final HostBindFailure? failure;

  final BufferedBroadcast<TableConnection> _connections =
      BufferedBroadcast<TableConnection>();

  final List<FakeSocketPair> pairs = [];
  int _nextId = 1;
  bool closed = false;

  @override
  Stream<TableConnection> get connections => _connections.stream;

  @override
  Future<(HostBinding?, HostBindFailure?)> bind() async {
    if (failure != null) return (null, failure);
    return (HostBinding(address: address, port: port), null);
  }

  /// A phone arrives. Call after the room has started.
  FakeSocketPair accept() {
    final pair = FakeSocketPair(
      hostId: 'host-$_nextId',
      phoneId: 'phone-$_nextId',
    );
    _nextId++;
    pairs.add(pair);
    _connections.add(pair.host);
    return pair;
  }

  @override
  Future<void> close() async {
    if (closed) return;
    closed = true;
    for (final pair in pairs) {
      unawaited(pair.host.close(code: TableCloseCode.goingAway));
    }
    // Not awaited: a bind failure has no listener at all, and the close must
    // still finish for the test.
    unawaited(_connections.close());
  }
}

/// Records whether the board announced itself, and never opens a socket.
class FakeTableAnnouncer implements TableAnnouncerControl {
  bool started = false;
  bool stopped = false;

  @override
  Future<bool> start() async {
    started = true;
    return true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

/// Lets queued stream events run to completion.
///
/// The fakes use asynchronous controllers on purpose — a synchronous one throws
/// when a handler sends while the controller is already firing — so a test that
/// wants the room's answer waits here instead of guessing at delays.
Future<void> settle() => pumpEventQueue();
