import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/core/constants/routes.dart';
import 'package:avalon_companion/database/database_provider.dart';
import 'package:avalon_companion/database/repositories/pin_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Phase 10 gate: the app stays usable for a phone held at the table —
/// large text, a protected settings screen, and no layout overflow.
void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    String? pinHash,
    Size size = const Size(1080, 2340),
    double dpr = 3.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (pinHash != null) initialPinHashProvider.overrideWithValue(pinHash),
        ],
        child: const AvalonApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  }

  GoRouter routerOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
          as GoRouter;

  testWidgets('settings survives a 200% text scale without overflowing', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester, size: const Size(720, 1560), dpr: 2.0);
    routerOf(tester).goNamed(RouteNames.settings);
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the dashboard survives a 200% text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester, size: const Size(720, 1560), dpr: 2.0);
    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();
    for (var seat = 0; seat < 5; seat++) {
      await tester.enterText(
        find.byKey(Key('setup_name_$seat')),
        'Player ${seat + 1}',
      );
    }
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('setup_continue')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a set PIN locks settings until it is entered', (tester) async {
    final hash = PinRepository.encode('1234');
    await pumpApp(tester, pinHash: hash);

    routerOf(tester).goNamed(RouteNames.settings);
    await tester.pumpAndSettle();
    expect(find.text('Settings are locked'), findsOneWidget);
    expect(find.text('GENERAL'), findsNothing);

    await tester.tap(find.byKey(const Key('settings_unlock')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('mc_pin_field')), '9999');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('That PIN is not right.'), findsOneWidget);
    expect(find.byKey(const Key('mc_pin_field')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('mc_pin_field')), '1234');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('GENERAL'), findsOneWidget);
    expect(find.text('Sound effects'), findsOneWidget);
  });

  testWidgets('without a PIN settings opens straight away', (tester) async {
    await pumpApp(tester);
    routerOf(tester).goNamed(RouteNames.settings);
    await tester.pumpAndSettle();

    expect(find.text('Settings are locked'), findsNothing);
    expect(find.text('GENERAL'), findsOneWidget);

    // The screen grew past one viewport; scroll until the security card shows.
    for (var i = 0; i < 12; i++) {
      if (find.byKey(const Key('settings_set_pin')).evaluate().isNotEmpty) break;
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('settings_set_pin')), findsOneWidget);
  });
}
