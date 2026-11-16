import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/game_engine/controllers/game_session_controller.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/models/phase.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The board review: the dashboard must be able to answer "who went on quest
/// 1?" from public state alone.
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

  void playQuest(
    ProviderContainer container, {
    required List<int> team,
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
    controller.proposeTeam(team);
    controller.recordVotes(approve: 5, reject: 0);
    controller.resolveTeamVote();
    controller.recordQuest(failCards: fails);
  }

  Future<void> openDashboard(WidgetTester tester) async {
    await tester.pump();
    await tester.tap(find.byKey(const Key('home_continue_game')));
    await tester.pumpAndSettle();
  }

  testWidgets('the dashboard lists who went on each resolved quest', (
    tester,
  ) async {
    await pumpApp(tester);
    final container = startMatch(tester);

    playQuest(container, team: [1, 2], fails: 1);
    await openDashboard(tester);

    expect(find.text('PAST QUEST TEAMS'), findsOneWidget);
    expect(find.text('Quest 1 · lost'), findsOneWidget);
    expect(find.text('Ann, Ben'), findsOneWidget);
    expect(find.text('Seats 1, 2'), findsOneWidget);
  });

  testWidgets('the log appears only once a quest has been played', (
    tester,
  ) async {
    await pumpApp(tester);
    startMatch(tester);
    await openDashboard(tester);

    expect(
      find.text('PAST QUEST TEAMS'),
      findsNothing,
      reason: 'nothing to review before the first quest resolves',
    );
  });

  testWidgets('a second quest adds its own team, not a replacement', (
    tester,
  ) async {
    await pumpApp(tester);
    final container = startMatch(tester);

    playQuest(container, team: [1, 2], fails: 0);
    playQuest(container, team: [3, 4, 5], fails: 1);
    await openDashboard(tester);

    expect(find.text('Quest 1 · won'), findsOneWidget);
    expect(find.text('Ann, Ben'), findsOneWidget);
    expect(find.text('Quest 2 · lost'), findsOneWidget);
    expect(find.text('Cara, Dev, Eli'), findsOneWidget);
  });
}
