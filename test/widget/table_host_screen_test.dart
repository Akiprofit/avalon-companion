import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/core/constants/routes.dart';
import 'package:avalon_companion/core/theme/app_metrics.dart';
import 'package:avalon_companion/core/widgets/confirmation_dialog.dart';
import 'package:avalon_companion/features/table_mode/host/table_host_controller.dart';
import 'package:avalon_companion/features/table_mode/model/room_code.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_invite.dart';
import 'package:avalon_companion/features/table_mode/protocol/table_message.dart';
import 'package:avalon_companion/features/table_mode/table_mode_providers.dart';
import 'package:avalon_companion/features/table_mode/widgets/join_qr.dart';
import 'package:avalon_companion/features/table_mode/widgets/room_code_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/fake_table_network.dart';

/// The board screen, driven end to end over in-memory sockets.
///
/// It is the one screen an MC sets on a tablet and then ignores, so it has to be
/// readable from across the table, honest about who is present, and impossible to
/// leave open by accident.
void main() {
  late FakeTableHostTransport transport;
  late FakeTableAnnouncer announcer;

  GoRouter routerOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
          as GoRouter;

  /// Boots the app with a board transport that never binds a port, then walks to
  /// the board. The fake bind resolves in a microtask, so the room is open when
  /// this returns.
  Future<void> pumpBoard(
    WidgetTester tester, {
    Size size = const Size(1080, 2340),
    double ratio = 3.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);

    transport = FakeTableHostTransport();
    announcer = FakeTableAnnouncer();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tableHostTransportFactoryProvider.overrideWithValue(() => transport),
          tableAnnouncerFactoryProvider.overrideWithValue((_, _) => announcer),
          tableBoardNameProvider.overrideWithValue('Test board'),
        ],
        child: const AvalonApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    routerOf(tester).goNamed(RouteNames.tableHost);
    await tester.pumpAndSettle();
  }

  /// Unmounts the app so the board's sweep timer is cancelled before the test
  /// framework checks for pending timers.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  /// The six characters the board is printing.
  String codeOnBoard(WidgetTester tester) =>
      tester.widget<RoomCodeCard>(find.byKey(const Key('table_host_code'))).code;

  testWidgets('the board shows a code, a QR and an empty table', (
    tester,
  ) async {
    await pumpBoard(tester);

    final code = codeOnBoard(tester);
    expect(code, hasLength(6));
    expect(
      RoomCode.normalise(code),
      code,
      reason: 'the code is printed in its stored, unambiguous form',
    );

    final qr = tester.widget<JoinQr>(find.byKey(const Key('table_host_qr')));
    final invite = TableInvite.parse(qr.data);
    expect(invite, isNotNull);
    expect(invite!.code, code, reason: 'the QR carries this room');
    expect(invite.host, '192.168.43.1');
    expect(invite.port, 8787);

    expect(find.text('192.168.43.1:8787'), findsOneWidget);
    expect(find.text('0 of 14'), findsOneWidget);
    expect(find.textContaining('No one has joined yet'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('a phone that joins appears by name, in join order', (
    tester,
  ) async {
    await pumpBoard(tester);
    final code = codeOnBoard(tester);

    final ana = transport.accept();
    ana.phone.send(HelloMessage(code: code, name: 'Ana').encode());
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('1 of 14'), findsOneWidget);
    expect(find.byKey(const ValueKey('seat_1')), findsOneWidget);

    final bo = transport.accept();
    bo.phone.send(HelloMessage(code: code, name: 'Bo').encode());
    await tester.pumpAndSettle();

    expect(find.text('2 of 14'), findsOneWidget);
    final first = tester.getRect(find.byKey(const ValueKey('seat_1')));
    final second = tester.getRect(find.byKey(const ValueKey('seat_2')));
    expect(
      second.top,
      greaterThan(first.top),
      reason: 'seats read down the card, like the table',
    );

    // The welcome is the phone's seat proof; it never appears on the board.
    final welcome = decodeTableFrame(ana.phone.received.first);
    expect(welcome, isA<TableDecoded>());
    expect((welcome as TableDecoded).message, isA<WelcomeMessage>());

    await unmount(tester);
  });

  testWidgets('a phone that drops is shown away, and can be released', (
    tester,
  ) async {
    await pumpBoard(tester);
    final code = codeOnBoard(tester);

    final ana = transport.accept();
    ana.phone.send(HelloMessage(code: code, name: 'Ana').encode());
    await tester.pumpAndSettle();
    expect(find.text('CONNECTED'), findsOneWidget);

    await ana.phone.vanish();
    await tester.pumpAndSettle();

    expect(find.text('AWAY'), findsOneWidget);
    expect(find.text('1 of 14'), findsOneWidget);

    final release = find.byTooltip('Release seat');
    await tester.ensureVisible(release);
    await tester.pumpAndSettle();
    await tester.tap(release);
    await tester.pumpAndSettle();

    expect(find.text('Release seat 1?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(ConfirmationDialog),
        matching: find.text('Release seat'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 of 14'), findsOneWidget);
    expect(find.textContaining('No one has joined yet'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('closing the room asks first, then goes Home', (tester) async {
    await pumpBoard(tester);
    final code = codeOnBoard(tester);
    final ana = transport.accept();
    ana.phone.send(HelloMessage(code: code, name: 'Ana').encode());
    await tester.pumpAndSettle();

    final close = find.byKey(const Key('table_host_close'));
    await tester.ensureVisible(close);
    await tester.pumpAndSettle();

    await tester.tap(close);
    await tester.pumpAndSettle();

    expect(find.text('Close the room?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('table_host_code')),
      findsOneWidget,
      reason: 'cancelling leaves the room open',
    );
    expect(transport.closed, isFalse);

    await tester.tap(close);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ConfirmationDialog),
        matching: find.text('Close the room'),
      ),
    );
    await tester.pumpAndSettle();
    // Closing crosses several awaits (subscriptions, announcer, sockets).
    // Each pump drains the microtask queue, so a few are enough for the
    // teardown to finish and the route to change.
    for (var i = 0; i < 10; i++) {
      await tester.pump();
    }

    expect(find.byKey(const Key('home_new_game')), findsOneWidget);
    expect(transport.closed, isTrue);
    expect(announcer.stopped, isTrue);
    expect(ana.phone.isClosed, isTrue);
  });

  testWidgets('a wide board is two columns inside the board measure', (
    tester,
  ) async {
    await pumpBoard(tester, size: const Size(2400, 1600), ratio: 2.0);

    final code = tester.getRect(find.byKey(const Key('table_host_code')));
    final seats = tester.getRect(find.byKey(const Key('table_host_seats')));

    expect(
      seats.left,
      greaterThan(code.right),
      reason: 'the QR and the seats sit side by side on a wide board',
    );
    expect(
      seats.top,
      lessThan(code.bottom),
      reason: 'the two columns are laid out in the same row',
    );
    expect(
      seats.right - code.left,
      lessThanOrEqualTo(kBoardContentWidth + 0.01),
      reason: 'a board is read across a table, not stretched across the glass',
    );
    expect(
      tester.getSize(find.byKey(const Key('table_host_qr'))).width,
      kJoinQrSizeLarge,
      reason: 'the QR is drawn larger where there is room',
    );

    await unmount(tester);
  });

  testWidgets('a phone-width board stacks the seats under the code', (
    tester,
  ) async {
    await pumpBoard(tester, size: const Size(800, 1600), ratio: 2.0);

    final code = tester.getRect(find.byKey(const Key('table_host_code')));
    final seats = tester.getRect(find.byKey(const Key('table_host_seats')));

    expect(seats.top, greaterThan(code.bottom));
    expect(seats.left, code.left);
    expect(
      tester.getSize(find.byKey(const Key('table_host_qr'))).width,
      kJoinQrSize,
    );

    await unmount(tester);
  });
}
