import 'package:avalon_companion/features/table_mode/host/table_host_controller.dart';
import 'package:avalon_companion/features/table_mode/host/table_host_server.dart';
import 'package:avalon_companion/features/table_mode/model/room_state.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_message.dart';
import 'package:avalon_companion/features/table_mode/table_mode_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_table_network.dart';

/// The board's controller: open the room, take joins, release seats, close.
void main() {
  late ProviderContainer container;
  late FakeTableHostTransport transport;
  late FakeTableAnnouncer announcer;
  late int announcerStarts;

  ProviderContainer makeContainer({HostBindFailure? failure}) {
    transport = FakeTableHostTransport(failure: failure);
    announcer = FakeTableAnnouncer();
    announcerStarts = 0;

    final scope = ProviderContainer(
      overrides: [
        tableHostTransportFactoryProvider.overrideWithValue(() => transport),
        tableAnnouncerFactoryProvider.overrideWithValue((announcement, port) {
          announcerStarts++;
          return announcer;
        }),
        tableBoardNameProvider.overrideWithValue('Test board'),
      ],
    );
    addTearDown(scope.dispose);
    return scope;
  }

  TableHostController controller() =>
      container.read(tableHostControllerProvider.notifier);

  TableHostState state() => container.read(tableHostControllerProvider);

  /// The room the board is showing. Fails the test if it is not running.
  RoomState room() {
    final current = state();
    expect(current, isA<TableHostRunning>());
    return (current as TableHostRunning).room;
  }

  /// Attaches a phone and sends a hello with the room's real code.
  FakeSocketPair join(String name) {
    final pair = transport.accept();
    pair.phone.send(HelloMessage(code: room().code, name: name).encode());
    return pair;
  }

  test('starting opens one room and announces it once', () async {
    container = makeContainer();

    await controller().start();

    final opened = room();
    expect(opened.code, hasLength(6));
    expect(opened.address, '192.168.43.1');
    expect(opened.port, 8787);
    expect(opened.isEmpty, isTrue);
    expect(announcerStarts, 1);
    expect(announcer.started, isTrue);
  });

  test('starting twice does not open a second room', () async {
    container = makeContainer();

    await controller().start();
    final code = room().code;
    await controller().start();

    expect(room().code, code);
    expect(announcerStarts, 1);
  });

  test('a phone that joins appears at the table, in join order', () async {
    container = makeContainer();
    await controller().start();

    join('Ana');
    await settle();
    expect(room().seats.map((s) => s.name), ['Ana']);

    join('Bo');
    await settle();
    expect(room().seats.map((s) => s.name), ['Ana', 'Bo']);
    expect(room().seatedCount, 2);
  });

  test('releasing a seat removes it from the board', () async {
    container = makeContainer();
    await controller().start();
    join('Ana');
    await settle();

    controller().releaseSeat(1);
    await settle();

    expect(room().isEmpty, isTrue);
  });

  test('a bind failure is a sentence, not a crash', () async {
    container = makeContainer(failure: HostBindFailure.noNetwork);

    await controller().start();

    expect(state(), isA<TableHostFailed>());
    expect((state() as TableHostFailed).failure, HostBindFailure.noNetwork);
    expect(transport.closed, isTrue);
  });

  test('closing the room stops the announcer and the sockets', () async {
    container = makeContainer();
    await controller().start();
    final ana = join('Ana');
    await settle();

    await controller().closeRoom();
    await settle();

    expect(state(), isA<TableHostClosed>());
    expect(announcer.stopped, isTrue);
    expect(transport.closed, isTrue);
    expect(ana.phone.isClosed, isTrue);
  });

  test('a phone leaving takes its seat with it', () async {
    container = makeContainer();
    await controller().start();
    final ana = join('Ana');
    await settle();

    ana.phone.send(const LeaveMessage().encode());
    await settle();

    expect(room().isEmpty, isTrue);
  });

  test('a phone that drops is shown away, and comes back to its seat', () async {
    container = makeContainer();
    await controller().start();

    final first = join('Ana');
    await settle();
    final welcome =
        (decodeTableFrame(first.phone.received.first) as TableDecoded).message;
    expect(welcome, isA<WelcomeMessage>());

    await first.phone.vanish();
    await settle();
    expect(room().seatAt(1)!.connected, isFalse);

    final returning = transport.accept();
    returning.phone.send(
      HelloMessage(
        code: room().code,
        name: 'Ana',
        token: (welcome as WelcomeMessage).token,
      ).encode(),
    );
    await settle();

    expect(room().seatedCount, 1);
    expect(room().seatAt(1)!.connected, isTrue);
    expect(room().seatAt(1)!.name, 'Ana');
  });

  test('a room that never started has nothing to release', () {
    container = makeContainer();

    controller().releaseSeat(1);

    expect(state(), isA<TableHostIdle>());
  });
}
