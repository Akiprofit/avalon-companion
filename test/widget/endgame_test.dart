import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/game_engine/controllers/game_session_controller.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/models/phase.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 8 gate: every victory path ends on the right screen, and the
/// accusation records only whether Merlin was named.
void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: AvalonApp()));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  }

  /// Five-player match driven through the engine, so the test does not have to
  /// tap through every vote three times over.
  ProviderContainer startMatch(WidgetTester tester) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AvalonApp)),
    );
    final defaults = AvalonTables.defaultComposition(5);
    final counts = <Character, int>{
      for (final character in Character.values)
        if ((defaults[character.label] ?? 0) > 0)
          character: defaults[character.label]!,
    };
    container.read(gameSessionProvider.notifier).start(
      names: const ['Ann', 'Ben', 'Cara', 'Dev', 'Eli'],
      composition: Composition(playerCount: 5, counts: counts),
    );
    return container;
  }

  /// Plays one full round: night, discussion, team, unanimous vote, quest.
  void playQuest(
    ProviderContainer container, {
    required int teamSize,
    required int fails,
  }) {
    final controller = container.read(gameSessionProvider.notifier);
    if (container.read(gameSessionProvider)?.phase == Phase.preparation) {
      controller.startNight();
    }
    if (container.read(gameSessionProvider)?.phase == Phase.night) {
      controller.endNight();
    }
    if (container.read(gameSessionProvider)?.phase == Phase.lordSelection) {
      controller.chooseLord(1);
    }
    if (container.read(gameSessionProvider)?.phase == Phase.dayDiscussion) {
      controller.beginTeamSelection();
    }
    controller.proposeTeam([for (var seat = 1; seat <= teamSize; seat++) seat]);
    controller.recordVotes(approve: 5, reject: 0);
    controller.resolveTeamVote();
    controller.recordQuest(failCards: fails);
  }

  Future<void> openDashboard(WidgetTester tester) async {
    // The home screen was built before the match existed, so let it rebuild
    // once before tapping Continue.
    await tester.pump();
    await tester.tap(find.byKey(const Key('home_continue_game')));
    await tester.pumpAndSettle();
  }

  testWidgets('three successful quests open the assassination', (tester) async {
    await pumpApp(tester);
    final container = startMatch(tester);
    playQuest(container, teamSize: 2, fails: 0);
    playQuest(container, teamSize: 3, fails: 0);
    playQuest(container, teamSize: 2, fails: 0);
    expect(container.read(gameSessionProvider)?.phase, Phase.assassination);

    await openDashboard(tester);
    expect(find.byKey(const Key('dashboard_open_assassination')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dashboard_open_assassination')));
    await tester.pumpAndSettle();

    expect(find.text('GOOD HAS COMPLETED THREE QUESTS.'), findsOneWidget);
    expect(find.byKey(const Key('assassination_named')), findsOneWidget);
    expect(find.byKey(const Key('assassination_survived')), findsOneWidget);
    // The name is never requested by the app.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('naming Merlin ends the match for Evil', (tester) async {
    await pumpApp(tester);
    final container = startMatch(tester);
    playQuest(container, teamSize: 2, fails: 0);
    playQuest(container, teamSize: 3, fails: 0);
    playQuest(container, teamSize: 2, fails: 0);
    await openDashboard(tester);

    await tester.tap(find.byKey(const Key('dashboard_open_assassination')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assassination_named')));
    await tester.pumpAndSettle();

    expect(find.text('Record a successful assassination?'), findsOneWidget);
    await tester.tap(find.text('Record Evil victory'));
    await tester.pumpAndSettle();

    expect(container.read(gameSessionProvider)?.phase, Phase.evilVictory);
    expect(container.read(gameSessionProvider)?.merlinIdentified, isTrue);
    expect(find.text('EVIL VICTORY'), findsWidgets);
    expect(
      find.text('The assassin named Merlin after three quests were won.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('victory_play_again')), findsOneWidget);
  });

  testWidgets('Merlin surviving ends the match for Good', (tester) async {
    await pumpApp(tester);
    final container = startMatch(tester);
    playQuest(container, teamSize: 2, fails: 0);
    playQuest(container, teamSize: 3, fails: 0);
    playQuest(container, teamSize: 2, fails: 0);
    await openDashboard(tester);

    await tester.tap(find.byKey(const Key('dashboard_open_assassination')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assassination_survived')));
    await tester.pumpAndSettle();

    expect(find.text("Record Merlin's escape?"), findsOneWidget);
    await tester.tap(find.text('Record Good victory'));
    await tester.pumpAndSettle();

    expect(container.read(gameSessionProvider)?.phase, Phase.goodVictory);
    expect(container.read(gameSessionProvider)?.merlinIdentified, isFalse);
    expect(find.text('GOOD VICTORY'), findsWidgets);
    expect(
      find.text(
        'Three quests were won and Merlin survived the accusation.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('three failed quests end the match for Evil', (tester) async {
    await pumpApp(tester);
    final container = startMatch(tester);
    playQuest(container, teamSize: 2, fails: 1);
    playQuest(container, teamSize: 3, fails: 1);
    playQuest(container, teamSize: 2, fails: 1);
    expect(container.read(gameSessionProvider)?.phase, Phase.evilVictory);
    expect(container.read(gameSessionProvider)?.questFailures, 3);

    await openDashboard(tester);
    expect(find.byKey(const Key('dashboard_pause')), findsNothing);
    await tester.tap(find.byKey(const Key('dashboard_open_results')));
    await tester.pumpAndSettle();

    expect(find.text('EVIL VICTORY'), findsWidgets);
    expect(find.text('Three quests failed. The realm fell.'), findsOneWidget);
  });

  testWidgets('Play Again keeps the table and clears the finished match', (
    tester,
  ) async {
    await pumpApp(tester);
    final container = startMatch(tester);
    playQuest(container, teamSize: 2, fails: 0);
    playQuest(container, teamSize: 3, fails: 0);
    playQuest(container, teamSize: 2, fails: 0);
    await openDashboard(tester);
    await tester.tap(find.byKey(const Key('dashboard_open_assassination')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assassination_survived')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record Good victory'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('victory_play_again')));
    await tester.pumpAndSettle();
    expect(find.text('Play again?'), findsOneWidget);

    await tester.tap(find.text('Start new match'));
    await tester.pumpAndSettle();

    final game = container.read(gameSessionProvider);
    expect(game, isNotNull);
    expect(game!.phase, Phase.preparation);
    expect(
      game.players.map((p) => p.name),
      ['Ann', 'Ben', 'Cara', 'Dev', 'Eli'],
      reason: 'the roster carries over untouched',
    );
    expect(game.questResults, isEmpty);
    expect(game.rejectionCount, 0);
    expect(game.merlinIdentified, isNull);
    expect(game.isFinished, isFalse);
    expect(find.text('PREPARATION'), findsWidgets);
  });

  testWidgets('leaving the result screen keeps the match for review', (
    tester,
  ) async {
    await pumpApp(tester);
    final container = startMatch(tester);
    playQuest(container, teamSize: 2, fails: 0);
    playQuest(container, teamSize: 3, fails: 0);
    playQuest(container, teamSize: 2, fails: 0);
    await openDashboard(tester);
    await tester.tap(find.byKey(const Key('dashboard_open_assassination')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assassination_survived')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record Good victory'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('victory_home')));
    await tester.pumpAndSettle();

    expect(container.read(gameSessionProvider)?.phase, Phase.goodVictory);
    expect(find.text('Review the Last Match'), findsOneWidget);
    expect(find.text('Last match ended in a Good victory.'), findsOneWidget);

    // Reviewing it opens the dashboard in its finished state.
    await tester.tap(find.byKey(const Key('home_continue_game')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard_open_results')), findsOneWidget);
  });
}
