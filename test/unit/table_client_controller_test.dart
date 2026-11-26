import 'dart:async';

import 'package:avalon_companion/features/table_mode/model/room_state.dart';
import 'package:avalon_companion/features/table_mode/model/seat.dart';
import 'package:avalon_companion/features/table_mode/player/table_client.dart';
import 'package:avalon_companion/features/table_mode/player/table_client_controller.dart';
import 'package:avalon_companion/features/table_mode/player/table_discovery.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_connection.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_invite.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_message.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_table_network.dart';

/// A discovery that answers at once, so no test waits on a broadcast.
class FakeDiscovery extends TableDiscovery {
  FakeDiscovery(this.answer);

  final TableInvite? answer;

  @override
  Future<TableInvite?> find(String code) async => answer;

  @override
  Future<void> cancel() async {}
}

/// A search that stays open until it is cancelled, like a real one listening.
class PendingDiscovery extends TableDiscovery {
  final Completer<TableInvite?> _completer = Completer<TableInvite?>();

  @override
  Future<TableInvite?> find(String code) => _completer.future;

  @override
  Future<void> cancel() async {
    if (!_completer.isCompleted) _completer.complete(null);
  }
}

/// The join flow as the phone sees it: find, name, sit, come back.
void main() {
  const invite = TableInvite(
    code: 'ABC234',
    host: '192.168.43.1',
    port: 8787,
  );
  const token = 'deadbeefdeadbeefdeadbeefdeadbeef';

  late ProviderContainer container;
  late List<FakeSocketPair> pairs;

  ProviderContainer makeContainer({
    TableDiscovery Function()? discovery,
    TableConnect? onConnect,
  }) {
    pairs = [];
    final scope = ProviderContainer(
      overrides: [
        tableDiscoveryFactoryProvider.overrideWithValue(
          discovery ?? () => FakeDiscovery(invite),
        ),
        tableConnectProvider.overrideWithValue(
          onConnect ??
              (uri) async {
                final pair = FakeSocketPair();
                pairs.add(pair);
                return pair.phone;
              },
        ),
      ],
    );
    addTearDown(scope.dispose);
    return scope;
  }

  TableClientController controller() =>
      container.read(tableClientControllerProvider.notifier);

  JoinState state() => container.read(tableClientControllerProvider);

  WelcomeMessage welcome({int seat = 1}) => WelcomeMessage(
    seat: seat,
    token: token,
    code: invite.code,
    capacity: TableProtocol.capacity,
    phase: RoomPhase.lobby,
    seats: [Seat(number: seat, name: 'Ana', connected: true)],
  );

  test('a code that no board answers fails, and can be tried again', () async {
    container = makeContainer(discovery: () => FakeDiscovery(null));

    await controller().locate('abc 234');

    expect(state(), isA<JoinLocateFailed>());
    expect((state() as JoinLocateFailed).code, 'ABC234');
  });

  test('a board that answers moves the phone to the name step', () async {
    container = makeContainer();

    await controller().locate('ABC234');

    expect(state(), isA<JoinNaming>());
    expect((state() as JoinNaming).invite.host, '192.168.43.1');
  });

  test('a scanned invite skips discovery entirely', () {
    container = makeContainer();

    controller().useInvite(invite);

    expect(state(), isA<JoinNaming>());
  });

  test('a typed address is an escape hatch, and a bad one is refused', () {
    container = makeContainer();

    expect(controller().useAddress('ABC234', '192.168.43.1:8787'), isTrue);
    expect((state() as JoinNaming).invite.host, '192.168.43.1');

    expect(controller().useAddress('ABC234', 'not-an-address'), isFalse);
    expect(controller().useAddress('ABC234', '192.168.43.1'), isFalse);
    expect(controller().useAddress('ABC234', ':8787'), isFalse);
    expect(controller().useAddress('ABC234', '192.168.43.1:0'), isFalse);
    expect(controller().useAddress('nope', '192.168.43.1:8787'), isFalse);
  });

  test('taking a seat says hello and lands on the seat screen', () async {
    container = makeContainer();
    await controller().locate('ABC234');

    final seating = controller().seat('  Ana  ');
    await settle();

    final hello =
        (decodeTableFrame(pairs.single.phone.sent.single) as TableDecoded)
            .message;
    expect((hello as HelloMessage).name, 'Ana');

    pairs.single.host.send(welcome().encode());
    await settle();
    await seating;

    expect(state(), isA<JoinSeated>());
    final seated = state() as JoinSeated;
    expect(seated.seat.seat, 1);
    expect(seated.invite.code, 'ABC234');
  });

  test('a name the board refuses is shown, not retried silently', () async {
    container = makeContainer();
    await controller().locate('ABC234');

    final seating = controller().seat('Ana');
    await settle();
    pairs.single.host.send(
      ErrorMessage.of(TableErrorCode.nameTaken).encode(),
    );
    await settle();
    await seating;

    expect(state(), isA<JoinRejected>());
    expect(
      (state() as JoinRejected).message,
      'Someone at the table already used that name.',
    );
  });

  test('a name that cannot be one never opens a socket', () async {
    container = makeContainer();
    await controller().locate('ABC234');

    await controller().seat('   ');

    expect(pairs, isEmpty);
    expect(state(), isA<JoinNaming>());
  });

  test('losing the board shows a reconnect instead of a dead screen', () async {
    container = makeContainer();
    await controller().locate('ABC234');
    final seating = controller().seat('Ana');
    await settle();
    pairs.single.host.send(welcome().encode());
    await settle();
    await seating;

    await pairs.single.phone.vanish();
    await settle();

    expect(state(), isA<JoinLost>());
    expect((state() as JoinLost).canRetry, isTrue);
  });

  test('the board closing the room ends the flow, with no retry offered', () async {
    container = makeContainer();
    await controller().locate('ABC234');
    final seating = controller().seat('Ana');
    await settle();
    pairs.single.host.send(welcome().encode());
    await settle();
    await seating;

    await pairs.single.host.close(code: TableCloseCode.goingAway);
    await settle();

    expect(state(), isA<JoinClosed>());
  });

  test('leaving releases the seat and returns to the start', () async {
    container = makeContainer();
    await controller().locate('ABC234');
    final seating = controller().seat('Ana');
    await settle();
    pairs.single.host.send(welcome().encode());
    await settle();
    await seating;

    await controller().leave();

    expect(state(), isA<JoinIdle>());
    expect(pairs.single.phone.isClosed, isTrue);
  });

  test('reset drops everything without telling the board anything', () async {
    container = makeContainer();
    await controller().locate('ABC234');

    await controller().reset();

    expect(state(), isA<JoinIdle>());
  });

  test('cancelling a search goes back to idle', () async {
    container = makeContainer(discovery: PendingDiscovery.new);

    final locating = controller().locate('ABC234');
    await settle();
    expect(state(), isA<JoinLocating>());

    await controller().cancelLocate();
    await locating;

    expect(state(), isA<JoinIdle>());
  });
}
