import 'package:avalon_companion/features/table_mode/host/table_room.dart';
import 'package:avalon_companion/features/table_mode/model/room_state.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_connection.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_message.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_table_network.dart';

/// The board's protocol, driven entirely over in-memory sockets.
void main() {
  late DateTime now;
  late TableRoom room;

  TableRoom makeRoom() => TableRoom(
    code: 'ABC234',
    address: '192.168.43.1',
    port: 8787,
    boardName: 'Avalon board',
    clock: () => now,
  );

  /// Every message of [type] this socket received, oldest first.
  List<TableMessage> messagesOfType(FakeTableConnection connection, Type type) {
    return [
      for (final raw in connection.received)
        if ((decodeTableFrame(raw) as TableDecoded).message case final message
            when message.runtimeType == type)
          message,
    ];
  }

  TableMessage lastMessage(FakeTableConnection connection) {
    final decoded = decodeTableFrame(connection.received.last);
    expect(decoded, isA<TableDecoded>());
    return (decoded as TableDecoded).message;
  }

  /// The one welcome this socket received. A seat is welcomed once.
  WelcomeMessage welcomeOf(FakeTableConnection connection) =>
      messagesOfType(connection, WelcomeMessage).single as WelcomeMessage;

  /// The one refusal this socket received.
  ErrorMessage errorOf(FakeTableConnection connection) =>
      messagesOfType(connection, ErrorMessage).single as ErrorMessage;

  setUp(() {
    now = DateTime(2026, 11, 26, 20);
    room = makeRoom();
  });

  tearDown(() async {
    await room.close();
  });

  /// Attaches a phone and seats it, returning both ends.
  Future<FakeSocketPair> seatPhone(
    String name, {
    String? token,
    String code = 'ABC234',
  }) async {
    final pair = FakeSocketPair();
    room.attach(pair.host);
    pair.phone.send(
      HelloMessage(code: code, name: name, token: token).encode(),
    );
    await settle();
    return pair;
  }

  test('a hello is answered with a welcome and the room state', () async {
    final pair = await seatPhone('Ana');

    final message = welcomeOf(pair.phone);
    expect(message.seat, 1);
    expect(message.code, 'ABC234');
    expect(message.capacity, TableProtocol.capacity);
    expect(message.phase, RoomPhase.lobby);
    expect(message.seats.single.name, 'Ana');
    expect(message.token, matches(RegExp(r'^[0-9a-f]{32}$')));

    expect(room.state.seatedCount, 1);
    expect(room.state.seats.single.connected, isTrue);
    expect(room.state.address, '192.168.43.1');
    expect(room.state.port, 8787);
  });

  test('a phone that found the wrong board is refused and let go', () async {
    final pair = FakeSocketPair();
    room.attach(pair.host);
    pair.phone.send(
      const HelloMessage(code: 'ZZZ999', name: 'Ana').encode(),
    );
    await settle();

    final error = lastMessage(pair.phone) as ErrorMessage;
    expect(error.code, TableErrorCode.roomNotFound);
    expect(pair.phone.closeCode, TableCloseCode.policy);
    expect(room.state.isEmpty, isTrue);
  });

  test('a seat already taken is refused without closing the socket', () async {
    await seatPhone('Ana');
    final second = await seatPhone('ana');

    expect(
      (lastMessage(second.phone) as ErrorMessage).code,
      TableErrorCode.nameTaken,
    );
    expect(second.phone.isClosed, isFalse);
    expect(room.state.seatedCount, 1);
  });

  test('a new seat is broadcast to everyone already at the table', () async {
    final first = await seatPhone('Ana');
    final statesBefore = messagesOfType(first.phone, StateMessage).length;

    await seatPhone('Bo');

    final states = messagesOfType(first.phone, StateMessage);
    expect(states, hasLength(statesBefore + 1));
    final latest = states.last as StateMessage;
    expect(latest.seats.map((s) => s.name), ['Ana', 'Bo']);
  });

  test('a ping is echoed with the same timestamp', () async {
    final pair = await seatPhone('Ana');
    pair.phone.send(const PingMessage(t: 1234567).encode());
    await settle();

    expect((lastMessage(pair.phone) as PongMessage).t, 1234567);
  });

  test('a leave releases the seat at once and closes cleanly', () async {
    final ana = await seatPhone('Ana');
    final bo = await seatPhone('Bo');

    ana.phone.send(const LeaveMessage().encode());
    await settle();

    expect(room.state.seats.map((s) => s.name), ['Bo']);
    expect(ana.phone.closeCode, TableCloseCode.normal);
    expect(
      (messagesOfType(bo.phone, StateMessage).last as StateMessage).seats,
      hasLength(1),
    );
  });

  test('a silent phone is marked away, not left sitting there connected', () async {
    final pair = await seatPhone('Ana');
    final watcher = await seatPhone('Bo');

    now = now.add(TableProtocol.silentTimeout);
    room.sweep();
    await settle();

    expect(pair.phone.closeCode, TableCloseCode.goingAway);
    expect(room.state.seatAt(1)!.connected, isFalse);
    expect(room.state.seatedCount, 2, reason: 'the seat is kept for a return');

    final presence = lastMessage(watcher.phone) as PresenceMessage;
    expect(presence.seat, 1);
    expect(presence.connected, isFalse);
  });

  test('a socket that never says hello is let go', () async {
    final pair = FakeSocketPair();
    room.attach(pair.host);

    now = now.add(TableProtocol.silentTimeout);
    room.sweep();
    await settle();

    expect(pair.phone.closeCode, TableCloseCode.policy);
    expect(room.state.isEmpty, isTrue);
  });

  test('a phone that lost Wi-Fi returns to the same seat and name', () async {
    final first = await seatPhone('Ana');
    final token = welcomeOf(first.phone).token;

    // Wi-Fi went away: the socket simply ends, with no close frame.
    await first.phone.vanish();
    await settle();
    expect(room.state.seatAt(1)!.connected, isFalse);

    final returning = await seatPhone('Ana again', token: token);

    final welcome = welcomeOf(returning.phone);
    expect(welcome.seat, 1, reason: 'the same seat, not the next one');
    expect(welcome.token, token);
    expect(welcome.seats.single.name, 'Ana');
    expect(room.state.seatAt(1)!.connected, isTrue);
    expect(room.state.seatedCount, 1);
  });

  test('a returning phone displaces a stale live socket on its seat', () async {
    final first = await seatPhone('Ana');
    final token = welcomeOf(first.phone).token;

    // The old socket is still open, but the phone reconnects anyway.
    final returning = await seatPhone('Ana', token: token);

    expect(welcomeOf(returning.phone).seat, 1);
    expect(first.phone.closeCode, TableCloseCode.normal);
    expect(errorOf(first.phone).code, TableErrorCode.seatReleased);
    expect(room.state.seatedCount, 1);
  });

  test('the board can release a seat that is not coming back', () async {
    final pair = await seatPhone('Ana');
    await seatPhone('Bo');
    await pair.phone.vanish();
    await settle();

    expect(room.releaseSeat(1), isTrue);
    await settle();

    expect(room.state.seats.map((s) => s.name), ['Bo']);
    expect(room.releaseSeat(1), isFalse, reason: 'nothing left to release');
  });

  test('releasing a live seat tells the phone why before closing it', () async {
    final pair = await seatPhone('Ana');

    expect(room.releaseSeat(1), isTrue);
    await settle();

    expect(
      (lastMessage(pair.phone) as ErrorMessage).code,
      TableErrorCode.seatReleased,
    );
    expect(pair.phone.closeCode, TableCloseCode.normal);
    expect(room.state.isEmpty, isTrue);
  });

  test('an oversized frame is refused and the socket closed', () async {
    final pair = await seatPhone('Ana');
    pair.phone.send('a' * (TableProtocol.maxFrameBytes + 1));
    await settle();

    expect(
      (lastMessage(pair.phone) as ErrorMessage).code,
      TableErrorCode.badMessage,
    );
    expect(pair.phone.closeCode, TableCloseCode.tooLarge);
  });

  test('a malformed frame is refused and the socket closed', () async {
    final pair = await seatPhone('Ana');
    pair.phone.send('not json');
    await settle();

    expect(
      (lastMessage(pair.phone) as ErrorMessage).code,
      TableErrorCode.badMessage,
    );
    expect(pair.phone.closeCode, TableCloseCode.policy);
  });

  test('an unknown request is refused but the seat is kept', () async {
    final pair = await seatPhone('Ana');
    pair.phone.send('{"v":1,"type":"deal","seats":[1]}');
    await settle();

    expect(
      (lastMessage(pair.phone) as ErrorMessage).code,
      TableErrorCode.unknownType,
    );
    expect(pair.phone.isClosed, isFalse);
    expect(room.state.seatAt(1)!.connected, isTrue);
  });

  test('a frame from a future version is refused as a version mismatch', () async {
    final pair = await seatPhone('Ana');
    pair.phone.send('{"v":99,"type":"ping","t":1}');
    await settle();

    expect(
      (lastMessage(pair.phone) as ErrorMessage).code,
      TableErrorCode.version,
    );
    expect(pair.phone.closeCode, TableCloseCode.policy);
  });

  test('the room publishes a public projection on every change', () async {
    final seen = <RoomState>[];
    final subscription = room.states.listen(seen.add);
    addTearDown(subscription.cancel);

    await seatPhone('Ana');
    await seatPhone('Bo');
    room.releaseSeat(2);
    await settle();

    expect(seen, isNotEmpty);
    expect(seen.last.seatedCount, 1);
    expect(seen.last.seats.single.name, 'Ana');
  });

  test('closing the room says goodbye to every phone', () async {
    final ana = await seatPhone('Ana');
    final bo = await seatPhone('Bo');

    await room.close();
    await settle();

    expect(ana.phone.closeCode, TableCloseCode.goingAway);
    expect(bo.phone.closeCode, TableCloseCode.goingAway);
    expect(room.state.seatedCount, 2, reason: 'the projection is not cleared');
  });
}
