import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/core/constants/routes.dart';
import 'package:avalon_companion/database/database_provider.dart';
import 'package:avalon_companion/features/settings/settings_controller.dart';
import 'package:avalon_companion/game_engine/controllers/game_session_controller.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/models/phase.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The two settings added on top of Phase 10: the King selection mode and the
/// extra delay after every narration line.
void main() {
  Composition compositionFor(int playerCount) {
    final defaults = AvalonTables.defaultComposition(playerCount);
    return Composition(
      playerCount: playerCount,
      counts: {
        for (final character in Character.values)
          if ((defaults[character.label] ?? 0) > 0)
            character: defaults[character.label]!,
      },
    );
  }

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    AppSettings settings = const AppSettings(),
    Size size = const Size(1080, 9000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialSettingsProvider.overrideWithValue(settings)],
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

  /// Starts a five-player match and stops right after the night.
  Future<ProviderContainer> pumpAfterNight(
    WidgetTester tester, {
    AppSettings settings = const AppSettings(),
  }) async {
    final container = await pumpApp(tester, settings: settings);
    container
        .read(gameSessionProvider.notifier)
        .start(
          names: const ['Ann', 'Ben', 'Cara', 'Dev', 'Eli'],
          composition: compositionFor(5),
        );
    container.read(gameSessionProvider.notifier)
      ..startNight()
      ..endNight();

    await tester.pump();
    await tester.tap(find.byKey(const Key('home_continue_game')));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('settings offers both King modes and the delay presets', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      settings: const AppSettings(narratorExtraDelay: Duration(seconds: 11)),
    );
    routerOf(tester).goNamed(RouteNames.settings);
    await tester.pumpAndSettle();

    expect(find.text('King selection mode'), findsOneWidget);
    expect(
      find.text('Choose how the quest leader is selected each round.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('settings_king_automatic')));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsProvider).kingSelectionMode,
      KingSelectionMode.automatic,
    );
    expect(
      find.textContaining('a new King leads each quest'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('settings_delay_3')));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsProvider).narratorExtraDelay,
      const Duration(seconds: 3),
    );
    expect(
      find.text(
        'Each narration slide will wait an additional 3 seconds before '
        'continuing.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a custom delay is shown and can be saved again', (tester) async {
    final container = await pumpApp(
      tester,
      settings: const AppSettings(narratorExtraDelay: Duration(seconds: 11)),
    );
    routerOf(tester).goNamed(RouteNames.settings);
    await tester.pumpAndSettle();

    expect(find.text('11s · Custom'), findsOneWidget);
    expect(
      find.text(
        'Each narration slide will wait an additional 11 seconds before '
        'continuing.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('settings_delay_custom')));
    await tester.pumpAndSettle();

    expect(find.text('Custom extra delay'), findsOneWidget);
    expect(find.byKey(const Key('settings_delay_slider')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings_delay_save')));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsProvider).narratorExtraDelay,
      const Duration(seconds: 11),
    );
  });

  testWidgets('zero delay reads as an immediate slide', (tester) async {
    await pumpApp(tester);
    routerOf(tester).goNamed(RouteNames.settings);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Each narration slide continues as soon as the line finishes.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('manual mode offers a draw, automatic mode spins by itself', (
    tester,
  ) async {
    await pumpAfterNight(tester);

    // Manual: the wheel waits for the MC.
    expect(find.byKey(const Key('dashboard_choose_lord')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dashboard_choose_lord')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lord_spin')), findsOneWidget);
    expect(find.text('THE LORD HAS BEEN CHOSEN'), findsNothing);
  });

  testWidgets('the automatic wheel lands without a tap', (tester) async {
    final container = await pumpAfterNight(
      tester,
      settings: const AppSettings(
        kingSelectionMode: KingSelectionMode.automatic,
      ),
    );

    await tester.tap(find.byKey(const Key('dashboard_choose_lord')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lord_spin')), findsNothing);
    expect(find.text('THE LORD HAS BEEN CHOSEN'), findsOneWidget);

    await tester.tap(find.byKey(const Key('lord_continue')));
    await tester.pumpAndSettle();

    final game = container.read(gameSessionProvider)!;
    expect(game.phase, Phase.dayDiscussion);
    expect(find.byKey(const Key('dashboard_choose_team')), findsOneWidget);
    expect(
      find.byKey(const Key('dashboard_draw_king')),
      findsNothing,
      reason: 'the automatic mode draws on its own',
    );
  });

  testWidgets('the dashboard can draw a new King between rounds', (
    tester,
  ) async {
    final container = await pumpAfterNight(tester);
    final controller = container.read(gameSessionProvider.notifier);
    controller.chooseLord(2);

    // Play one round so a King has actually served.
    final size = container.read(gameSessionProvider)!.requiredTeamSize;
    controller
      ..beginTeamSelection()
      ..proposeTeam([for (var seat = 1; seat <= size; seat++) seat])
      ..recordVotes(approve: 5, reject: 0)
      ..resolveTeamVote()
      ..recordQuest(failCards: 0);
    await tester.pumpAndSettle();

    final previousKing = container.read(gameSessionProvider)!.leaderSeat;
    expect(find.byKey(const Key('dashboard_draw_king')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dashboard_draw_king')));
    await tester.pumpAndSettle();

    expect(container.read(gameSessionProvider)!.phase, Phase.lordSelection);
    expect(find.text('CHOOSE THE LORD'), findsOneWidget);

    await tester.tap(find.byKey(const Key('lord_spin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lord_continue')));
    await tester.pumpAndSettle();

    final game = container.read(gameSessionProvider)!;
    expect(game.phase, Phase.dayDiscussion);
    expect(
      game.leaderSeat,
      isNot(previousKing),
      reason: 'the King who has just served is left out of the draw',
    );
    expect(game.questNumber, 2, reason: 'a draw never repeats a round');
  });
}
