import 'dart:async';

import 'package:avalon_companion/features/table_mode/host/table_host_server.dart';
import 'package:avalon_companion/features/table_mode/host/table_room.dart';
import 'package:avalon_companion/features/table_mode/player/io_table_transport.dart';
import 'package:avalon_companion/features/table_mode/player/table_client.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_connection.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_invite.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

/// The `dart:io` adapters, over a real loopback socket.
///
/// Everything else in Table Mode is tested on in-memory connections; this file
/// exists so the one place that speaks WebSocket is not the one place nobody
/// ever ran. It binds port 0, so it can never collide with a real board.
void main() {
  late IoTableHostServer server;
  late TableRoom room;
  late StreamSubscription<TableConnection> accepted;
  late List<TableConnection> hosted;
  late TableInvite invite;
  late List<TableClient> clients;

  setUp(() async {
    server = IoTableHostServer(
      findAddress: () async => '127.0.0.1',
      ports: const [0],
    );
    final (binding, failure) = await server.bind();
    expect(failure, isNull, reason: 'loopback must bind');
    expect(binding, isNotNull);

    room = TableRoom(
      code: 'ABC234',
      address: binding!.address,
      port: binding.port,
      boardName: 'Loopback board',
    );
    hosted = [];
    accepted = server.connections.listen((connection) {
      hosted.add(connection);
      room.attach(connection);
    });
    invite = TableInvite(
      code: 'ABC234',
      host: '127.0.0.1',
      port: binding.port,
    );
    clients = [];
  });

  tearDown(() async {
    for (final client in clients) {
      await client.dispose();
    }
    await accepted.cancel();
    await room.close();
    await server.close();
  });

  /// Polls until [condition] holds, so a real socket has time to settle.
  Future<void> waitFor(bool Function() condition, {String? reason}) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail(reason ?? 'condition never became true');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<TableClient> phone(String name) async {
    final client = TableClient(
      invite: invite,
      name: name,
      connect: connectTableSocket,
    );
    clients.add(client);
    await client.open();
    return client;
  }

  test('a real socket joins, is welcomed and appears on the board', () async {
    final ana = await phone('Ana');

    expect(ana.state, isA<TableClientSeated>());
    expect((ana.state as TableClientSeated).seat, 1);
    expect(ana.token, isNotNull);

    expect(room.state.seatedCount, 1);
    expect(room.state.seatAt(1)!.name, 'Ana');
    expect(room.state.seatAt(1)!.connected, isTrue);
  });

  test('two phones see each other, and a leave frees the seat', () async {
    final ana = await phone('Ana');
    final bo = await phone('Bo');

    expect((bo.state as TableClientSeated).seats.map((s) => s.name), [
      'Ana',
      'Bo',
    ]);

    await bo.leave();
    // The board handles the leave frame before the socket closes.
    await waitFor(
      () => room.state.seatedCount == 1,
      reason: 'the board must drop a seat whose phone left',
    );

    expect(room.state.seats.map((s) => s.name), ['Ana']);
    // The seat is freed by the leave frame, not by the watchdog: the board must
    // have read a normal close, not the abnormal 1006 of a torn-down socket.
    await waitFor(
      () => hosted.any((c) => c.closeCode == TableCloseCode.normal),
      reason: 'the phone must leave with a normal close so the frame lands',
    );
    await waitFor(
      () {
        final state = ana.state;
        return state is TableClientSeated && state.seats.length == 1;
      },
      reason: 'the other phone must see the seat go',
    );
    final seated = ana.state as TableClientSeated;
    expect(seated.seats.map((s) => s.name), ['Ana']);
  });

  test('a phone that reconnects gets its own seat back', () async {
    final ana = await phone('Ana');
    final token = ana.token;
    expect(token, isNotNull);

    // The Wi-Fi drops: the board's end of the socket dies without a goodbye,
    // which is what a phone walking out of range looks like from the tablet.
    await hosted.single.close(code: 4000, reason: 'wifi lost');
    await waitFor(
      () => ana.state is TableClientLost,
      reason: 'a dead socket must be reported as a loss',
    );
    await waitFor(
      () => room.state.seatAt(1)!.connected == false,
      reason: 'the board must show the phone away',
    );

    // The same client, so the token it kept in memory is offered again.
    await ana.open();
    await waitFor(
      () => ana.state is TableClientSeated,
      reason: 'the phone must be welcomed back',
    );

    expect((ana.state as TableClientSeated).seat, 1);
    expect(ana.token, token);
    expect(room.state.seatedCount, 1);
    expect(room.state.seatAt(1)!.connected, isTrue);
    expect(room.state.seatAt(1)!.name, 'Ana');
  });

  test('a wrong code is refused over a real socket', () async {
    final wrong = TableClient(
      invite: TableInvite(code: 'ZZZ999', host: '127.0.0.1', port: invite.port),
      name: 'Ana',
      connect: connectTableSocket,
    );
    clients.add(wrong);
    await wrong.open();

    expect(wrong.state, isA<TableClientRejected>());
    expect(
      (wrong.state as TableClientRejected).code,
      TableErrorCode.roomNotFound,
      reason: 'the board says which rule was broken',
    );
    expect(room.state.isEmpty, isTrue);
  });
}
