import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/core/constants/routes.dart';
import 'package:avalon_companion/database/database_provider.dart';
import 'package:avalon_companion/features/settings/settings_controller.dart';
import 'package:avalon_companion/features/setup/setup_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The Big table switch: off on a fresh install, and only then does setup offer
/// the 11–14 player house sizes.
void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    AppSettings settings = const AppSettings(),
    List<String>? lastRoster,
  }) async {
    tester.view.physicalSize = const Size(1080, 9000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSettingsProvider.overrideWithValue(settings),
          if (lastRoster != null)
            lastRosterProvider.overrideWith((ref) async => lastRoster),
        ],
        child: const AvalonApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    return ProviderScope.containerOf(tester.element(find.byType(AvalonApp)));
  }

  GoRouter routerOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
          as GoRouter;

  testWidgets('a fresh install offers only 5 to 10, in Settings and setup', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    expect(container.read(settingsProvider).bigTable, isFalse);

    routerOf(tester).goNamed(RouteNames.settings);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_big_table')), findsOneWidget);
    expect(find.textContaining('Not enough room at the table?'), findsOneWidget);
    expect(
      find.byKey(const Key('settings_default_count_10')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings_default_count_11')),
      findsNothing,
      reason: 'the house sizes stay hidden until the switch is turned on',
    );

    routerOf(tester).goNamed(RouteNames.home);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setup_count_10')), findsOneWidget);
    expect(find.byKey(const Key('setup_count_11')), findsNothing);
    expect(find.byKey(const Key('setup_house_table_note')), findsNothing);
  });

  testWidgets('turning the switch on unlocks 11 to 14 and says it is a house rule', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    routerOf(tester).goNamed(RouteNames.settings);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('settings_big_table')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('settings_big_table')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).bigTable, isTrue);
    expect(find.textContaining('Setup offers 11 to 14 players'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('settings_default_count_14')),
    );
    await tester.pumpAndSettle();
    for (var count = 11; count <= 14; count++) {
      expect(
        find.byKey(Key('settings_default_count_$count')),
        findsOneWidget,
        reason: '$count should be selectable',
      );
    }

    routerOf(tester).goNamed(RouteNames.home);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();

    for (var count = 11; count <= 14; count++) {
      expect(
        find.byKey(Key('setup_count_$count')),
        findsOneWidget,
        reason: '$count seats should be offered in setup',
      );
    }
    expect(find.byKey(const Key('setup_house_table_note')), findsOneWidget);
    expect(
      find.textContaining('Avalon is officially five to ten'),
      findsWidgets,
      reason: 'setup never presents the house sizes as standard',
    );
  });

  testWidgets('a 14 seat match can be set up and started', (tester) async {
    await pumpApp(tester, settings: const AppSettings(bigTable: true));
    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setup_count_14')));
    await tester.pumpAndSettle();

    for (var seat = 0; seat < 14; seat++) {
      await tester.enterText(
        find.byKey(Key('setup_name_$seat')),
        'Player ${seat + 1}',
      );
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setup_continue')));
    await tester.pumpAndSettle();
    expect(find.text('PREPARATION'), findsOneWidget);
    expect(find.text('14 players are seated.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('preparation_begin')));
    await tester.pumpAndSettle();
    expect(find.text('14 seated'), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'fourteen seats must lay out on a phone without overflowing',
    );
  });

  testWidgets('a 12 seat last table is only offered when Big table is on', (
    tester,
  ) async {
    final roster = [for (var seat = 1; seat <= 12; seat++) 'Player $seat'];

    final container = await pumpApp(tester, lastRoster: roster);
    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('setup_use_last_table')),
      findsNothing,
      reason: 'the stored roster is larger than the app currently offers',
    );

    routerOf(tester).goNamed(RouteNames.home);
    await tester.pumpAndSettle();
    container.read(settingsProvider.notifier).setBigTable(true);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('setup_use_last_table')), findsOneWidget);
    expect(find.text('Use the last table · 12 players'), findsOneWidget);
  });

  testWidgets('a stored default above ten falls back when the switch goes off', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      settings: const AppSettings(bigTable: true, defaultPlayerCount: 13),
    );
    expect(container.read(settingsProvider).defaultPlayerCount, 13);

    container.read(settingsProvider.notifier).setBigTable(false);

    expect(container.read(settingsProvider).bigTable, isFalse);
    expect(
      container.read(settingsProvider).defaultPlayerCount,
      10,
      reason: 'setup must not seed a count the app no longer offers',
    );
  });
}
