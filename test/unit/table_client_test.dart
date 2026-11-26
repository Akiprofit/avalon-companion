import 'package:avalon_companion/features/table_mode/model/room_state.dart';
import 'package:avalon_companion/features/table_mode/model/seat.dart';
import 'package:avalon_companion/features/table_mode/player/table_client.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_connection.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_invite.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_message.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_table_network.dart';

/// The phone's side: say hello, take the seat, come back to it after Wi-Fi.
void main() {
  const invite = TableInvite(
    code: 'ABC234',
    host: '192.168.43.1',
    port: 8787,
  );
  const token = 'c0ffee00c0ffee00c0ffee00c0ffee00';

  WelcomeMessage welcome({int seat = 1, String name = 'Ana'}) => WelcomeMessage(
    seat: seat,
    token: token,
    code: invite.code,
    capacity: TableProtocol.capacity,
    phase: RoomPhase.lobby,
    seats: [Seat(number: seat, name: name, connected: true)],
  );

  late List<FakeSocketPair> pairs;
  late List<Object> connectAttempts;

  /// A connect that never throws and hands the test both ends.
  Future<TableConnection> connect(Uri uri) async {
    connectAttempts.add(uri);
    final pair = FakeSocketPair();
    pairs.add(pair);
    return pair.phone;
  }

  /// A connect that fails the way an unreachable board does.
  Future<TableConnection> refuse(Uri uri) async {
    connectAttempts.add(uri);
    throw const SocketExceptionLike();
  }

  TableClient makeClient({
    TableConnect? onConnect,
    DateTime Function()? clock,
    Duration reconnectWindow = TableProtocol.reconnectWindow,
  }) {
    return TableClient(
      invite: invite,
      name: 'Ana',
      connect: onConnect ?? connect,
      clock: clock,
      reconnectWindow: reconnectWindow,
    );
  }

  /// The last frame a phone sent, as a message.
  TableMessage sentByPhone() {
    final decoded = decodeTableFrame(pairs.last.phone.sent.last);
    return (decoded as TableDecoded).message;
  }

  setUp(() {
    pairs = [];
    connectAttempts = [];
  });

  test('open says hello with the code and name, then takes the seat', () async {
    final client = makeClient();
    addTearDown(client.dispose);

    final opening = client.open();
    await settle();

    expect(connectAttempts.single.toString(), invite.socketUri.toString());
    final hello = sentByPhone() as HelloMessage;
    expect(hello.code, 'ABC234');
    expect(hello.name, 'Ana');
    expect(hello.token, isNull, reason: 'a first join has no token yet');

    pairs.last.host.send(welcome().encode());
    await settle();
    await opening;

    final state = client.state;
    expect(state, isA<TableClientSeated>());
    expect((state as TableClientSeated).seat, 1);
    expect(state.seats.single.name, 'Ana');
    expect(client.token, token);
  });

  test('state and presence frames update the seat without a reconnect', () async {
    final client = makeClient();
    addTearDown(client.dispose);

    final opening = client.open();
    await settle();
    pairs.last.host.send(welcome().encode());
    await settle();
    await opening;

    pairs.last.host.send(
      const PresenceMessage(seat: 1, connected: false).encode(),
    );
    await settle();
    expect((client.state as TableClientSeated).seats.single.connected, isFalse);

    pairs.last.host.send(
      const StateMessage(
        capacity: TableProtocol.capacity,
        phase: RoomPhase.lobby,
        seats: [
          Seat(number: 1, name: 'Ana', connected: true),
          Seat(number: 2, name: 'Bo', connected: true),
        ],
      ).encode(),
    );
    await settle();

    final seated = client.state as TableClientSeated;
    expect(seated.seats.map((s) => s.name), ['Ana', 'Bo']);
    expect(seated.seat, 1, reason: 'the phone keeps its own seat number');
  });

  test('after losing the socket, a reconnect offers the stored token', () async {
    final client = makeClient();
    addTearDown(client.dispose);

    final first = client.open();
    await settle();
    pairs.last.host.send(welcome().encode());
    await settle();
    await first;
    expect(client.token, token);

    // Wi-Fi drops: the socket ends with no close frame.
    await pairs.last.phone.vanish();
    await settle();
    expect(client.state, isA<TableClientLost>());

    final again = client.open();
    await settle();

    final hello = sentByPhone() as HelloMessage;
    expect(hello.token, token, reason: 'the seat is claimed, not taken anew');
    expect(pairs, hasLength(2));

    pairs.last.host.send(welcome().encode());
    await settle();
    await again;
    expect(client.state, isA<TableClientSeated>());
  });

  test('a refusal from the board becomes a readable rejection', () async {
    final client = makeClient();
    addTearDown(client.dispose);

    final opening = client.open();
    await settle();
    pairs.last.host.send(
      ErrorMessage.of(TableErrorCode.nameTaken).encode(),
    );
    await settle();
    await opening;

    final state = client.state;
    expect(state, isA<TableClientRejected>());
    expect(
      (state as TableClientRejected).message,
      'Someone at the table already used that name.',
    );
  });

  test('an unreachable board is a loss that may be retried', () async {
    final client = makeClient(onConnect: refuse);
    addTearDown(client.dispose);

    await client.open();
    await settle();

    final state = client.state as TableClientLost;
    expect(state.attempt, 1);
    expect(state.canRetry, isTrue);
  });

  test('the retry backoff is 1, 2, 3, then 5 seconds', () {
    expect(TableClient.retryDelay(1), const Duration(seconds: 1));
    expect(TableClient.retryDelay(2), const Duration(seconds: 2));
    expect(TableClient.retryDelay(3), const Duration(seconds: 3));
    expect(TableClient.retryDelay(4), const Duration(seconds: 5));
    expect(TableClient.retryDelay(99), const Duration(seconds: 5));
  });

  test('the reconnect window runs out, and then the seat is not chased', () async {
    var now = DateTime(2026, 11, 26, 20);
    final client = makeClient(
      onConnect: refuse,
      clock: () => now,
      reconnectWindow: const Duration(minutes: 2),
    );
    addTearDown(client.dispose);

    await client.open();
    await settle();
    expect((client.state as TableClientLost).canRetry, isTrue);

    now = now.add(const Duration(minutes: 3));
    await client.open();
    await settle();

    expect((client.state as TableClientLost).canRetry, isFalse);
  });

  test('a board that closes the room is not retried', () async {
    final client = makeClient();
    addTearDown(client.dispose);

    final opening = client.open();
    await settle();
    pairs.last.host.send(welcome().encode());
    await settle();
    await opening;

    await pairs.last.host.close(code: TableCloseCode.goingAway);
    await settle();

    expect(client.state, isA<TableClientClosed>());
  });

  test('a socket that ends while seated is a loss, not a closed room', () async {
    final client = makeClient();
    addTearDown(client.dispose);

    final opening = client.open();
    await settle();
    pairs.last.host.send(welcome().encode());
    await settle();
    await opening;

    await pairs.last.phone.vanish();
    await settle();

    expect(client.state, isA<TableClientLost>());
  });

  test('ping says "still here" on the live socket', () async {
    final client = makeClient();
    addTearDown(client.dispose);

    final opening = client.open();
    await settle();
    pairs.last.host.send(welcome().encode());
    await settle();
    await opening;

    client.ping();
    await settle();

    expect(sentByPhone(), isA<PingMessage>());
  });

  test('leave tells the board before the socket closes', () async {
    final client = makeClient();
    final opening = client.open();
    await settle();
    pairs.last.host.send(welcome().encode());
    await settle();
    await opening;

    await client.leave();

    final messages = [
      for (final raw in pairs.last.phone.sent)
        (decodeTableFrame(raw) as TableDecoded).message,
    ];
    expect(messages.last, isA<LeaveMessage>());
    expect(pairs.last.phone.isClosed, isTrue);
    expect(pairs.last.host.closeCode, TableCloseCode.normal);
  });

  test('disposing during a pending open resolves it instead of hanging', () async {
    final client = makeClient();
    final opening = client.open();
    await settle();

    await client.dispose();
    await opening;

    expect(
      client.state,
      isNot(isA<TableClientSeated>()),
      reason: 'a disposed client must not report a live seat',
    );
    expect(pairs.single.phone.isClosed, isTrue);
  });

  test('the client never holds a character or a role', () async {
    final client = makeClient();
    addTearDown(client.dispose);

    final opening = client.open();
    await settle();
    pairs.last.host.send(welcome().encode());
    await settle();
    await opening;

    final seated = client.state as TableClientSeated;
    final frame = WelcomeMessage(
      seat: seated.seat,
      token: seated.token,
      code: invite.code,
      capacity: seated.capacity,
      phase: seated.phase,
      seats: seated.seats,
    ).encode();

    for (final forbidden in ['character', 'role', 'evil', 'merlin']) {
      expect(frame.toLowerCase(), isNot(contains(forbidden)));
    }
  });
}

/// Stands in for the `SocketException` a refused connect throws, so the unit
/// test does not need `dart:io`.
class SocketExceptionLike implements Exception {
  const SocketExceptionLike();

  @override
  String toString() => 'SocketExceptionLike: connection refused';
}
