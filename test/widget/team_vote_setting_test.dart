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

/// The team approval vote switch: the base game keeps it on, and a table that
/// plays without the vote goes from the chosen team straight to the quest.
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
  }) async {
    tester.view.physicalSize = const Size(1080, 9000);
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

  /// A five-player match taken to the first day and the team selection screen.
  Future<ProviderContainer> pumpTeamSelection(
    WidgetTester tester, {
    required bool voteEnabled,
  }) async {
    final container = await pumpApp(
      tester,
      settings: AppSettings(teamVoteEnabled: voteEnabled),
    );

    final controller = container.read(gameSessionProvider.notifier);
    controller.start(
      names: const ['Ann', 'Ben', 'Cara', 'Dev', 'Eli'],
      composition: compositionFor(5),
    );
    controller
      ..startNight()
      ..endNight()
      ..chooseLord(1)
      ..beginTeamSelection();

    await tester.pump();
    await tester.tap(find.byKey(const Key('home_continue_game')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboard_choose_team')));
    await tester.pumpAndSettle();

    return container;
  }

  Future<void> chooseTeamAndConfirm(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('team_selection_seat_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team_selection_seat_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team_selection_confirm')));
    await tester.pumpAndSettle();
  }

  testWidgets('Settings offers the approval vote switch and keeps it', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    routerOf(tester).goNamed(RouteNames.settings);
    await tester.pumpAndSettle();

    expect(find.text('Team approval vote'), findsOneWidget);
    expect(
      find.text(
        'Each proposed team is approved or rejected before the cards are '
        'played.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('settings_team_vote')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).teamVoteEnabled, isFalse);
    expect(
      find.text(
        'The leader\'s team goes straight to the quest, and rejections stop '
        'being counted.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('with the vote off a confirmed team opens the quest, not a vote', (
    tester,
  ) async {
    final container = await pumpTeamSelection(tester, voteEnabled: false);

    expect(find.byKey(const Key('team_selection_vote_off')), findsOneWidget);
    expect(find.text('Off'), findsOneWidget,
        reason: 'the progress strip says the vote is off');

    await chooseTeamAndConfirm(tester);

    final game = container.read(gameSessionProvider)!;
    expect(game.phase, Phase.questResolution);
    expect(game.currentTeam, [1, 2]);
    expect(game.rejectionCount, 0);
    expect(find.text('QUEST RESOLUTION'), findsWidgets);
    expect(find.text('TEAM VOTING'), findsNothing);
  });

  testWidgets('with the vote on the same team still goes to the vote', (
    tester,
  ) async {
    final container = await pumpTeamSelection(tester, voteEnabled: true);

    expect(find.byKey(const Key('team_selection_vote_off')), findsNothing);
    expect(find.text('REJECTED'), findsWidgets);

    await chooseTeamAndConfirm(tester);

    expect(container.read(gameSessionProvider)!.phase, Phase.teamVoting);
    expect(find.text('TEAM VOTING'), findsWidgets);
  });

  testWidgets('a voteless quest returns to the day with a new King', (
    tester,
  ) async {
    final container = await pumpTeamSelection(tester, voteEnabled: false);
    await chooseTeamAndConfirm(tester);

    // Two success cards, recorded from the quest screen.
    await tester.tap(find.byKey(const Key('quest_success_increment')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quest_success_increment')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quest_resolve')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quest_confirm_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quest_outcome_continue')));
    await tester.pumpAndSettle();

    final game = container.read(gameSessionProvider)!;
    expect(game.phase, Phase.dayDiscussion);
    expect(game.questNumber, 2);
    expect(game.questSuccesses, 1);
    expect(game.leaderSeat, 2, reason: 'the token passed without a vote');
  });
}
