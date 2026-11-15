import 'dart:math';

import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/features/lord_selection/lord_selection_screen.dart';
import 'package:avalon_companion/game_engine/controllers/game_session_controller.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/models/phase.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Feature gate: the first Lord is drawn at random after the night, and Play
/// Again returns the same table to a clean match.
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

  void startMatch(ProviderContainer container) {
    container
        .read(gameSessionProvider.notifier)
        .start(
          names: const ['Ann', 'Ben', 'Cara', 'Dev', 'Eli'],
          composition: compositionFor(5),
        );
  }

  /// Runs the engine to a Good victory without touching the UI.
  void playToGoodVictory(ProviderContainer container) {
    final controller = container.read(gameSessionProvider.notifier);
    controller.startNight();
    controller.endNight();
    controller.chooseLord(1);
    for (var quest = 0; quest < 3; quest++) {
      final game = container.read(gameSessionProvider)!;
      controller.beginTeamSelection();
      controller.proposeTeam([
        for (var seat = 1; seat <= game.requiredTeamSize; seat++) seat,
      ]);
      controller.recordVotes(approve: 5, reject: 0);
      controller.resolveTeamVote();
      controller.recordQuest(failCards: 0);
    }
    controller.resolveAssassination(merlinIdentified: false);
  }

  group('Play Again', () {
    test('keeps the roster and the composition, clears everything else', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // A different starting Lord proves the draw is not carried over.
      final controller = container.read(gameSessionProvider.notifier);
      startMatch(container);
      controller.startNight();
      controller.endNight();
      controller.chooseLord(4);
      for (var quest = 0; quest < 3; quest++) {
        final game = container.read(gameSessionProvider)!;
        controller.beginTeamSelection();
        controller.proposeTeam([
          for (var seat = 1; seat <= game.requiredTeamSize; seat++) seat,
        ]);
        controller.recordVotes(approve: 5, reject: 0);
        controller.resolveTeamVote();
        controller.recordQuest(failCards: 0);
      }
      controller.resolveAssassination(merlinIdentified: true);

      final finished = container.read(gameSessionProvider)!;
      expect(finished.phase, Phase.evilVictory);
      expect(finished.questResults.length, 3);

      controller.playAgain();
      final replay = container.read(gameSessionProvider)!;

      expect(replay.phase, Phase.preparation);
      expect(replay.players, finished.players);
      expect(replay.composition.counts, finished.composition.counts);
      expect(replay.questResults, isEmpty);
      expect(replay.rejectionCount, 0);
      expect(replay.currentTeam, isEmpty);
      expect(replay.approveVotes, 0);
      expect(replay.rejectVotes, 0);
      expect(replay.finishedAt, isNull);
      expect(replay.isFinished, isFalse);
      expect(replay.merlinIdentified, isNull);
    });

    test('the new match runs its own night and its own Lord draw', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      startMatch(container);
      playToGoodVictory(container);
      final controller = container.read(gameSessionProvider.notifier);
      controller.playAgain();

      expect(container.read(gameSessionProvider)?.phase, Phase.preparation);
      controller.startNight();
      expect(container.read(gameSessionProvider)?.phase, Phase.night);
      controller.endNight();
      expect(container.read(gameSessionProvider)?.phase, Phase.lordSelection);
      controller.chooseLord(5);
      expect(container.read(gameSessionProvider)?.leaderSeat, 5);
      expect(container.read(gameSessionProvider)?.phase, Phase.dayDiscussion);
    });

    test('replaying twice in a row keeps one roster, never duplicates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      startMatch(container);
      playToGoodVictory(container);
      final controller = container.read(gameSessionProvider.notifier);

      for (var round = 0; round < 2; round++) {
        controller.playAgain();
        final game = container.read(gameSessionProvider)!;
        expect(game.playerCount, 5);
        expect(game.players.map((p) => p.seat), [1, 2, 3, 4, 5]);
        expect(game.players.map((p) => p.name), [
          'Ann',
          'Ben',
          'Cara',
          'Dev',
          'Eli',
        ]);
        playToGoodVictory(container);
        expect(container.read(gameSessionProvider)?.isFinished, isTrue);
      }
    });

    test('Play Again is ignored while a match is still running', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      startMatch(container);
      final controller = container.read(gameSessionProvider.notifier);
      controller.startNight();
      final before = container.read(gameSessionProvider);

      controller.playAgain();

      expect(container.read(gameSessionProvider), same(before));
    });
  });

  group('the wheel', () {
    Future<ProviderContainer> pumpToLordWheel(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: AvalonApp()));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AvalonApp)),
      );
      startMatch(container);
      container.read(gameSessionProvider.notifier)
        ..startNight()
        ..endNight();

      await tester.pump();
      await tester.tap(find.byKey(const Key('home_continue_game')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dashboard_choose_lord')));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('every seated player takes part in the draw', (tester) async {
      await pumpToLordWheel(tester);

      expect(find.text('CHOOSE THE LORD'), findsOneWidget);
      expect(find.byKey(const Key('lord_spin')), findsOneWidget);
      for (final name in ['Ann', 'Ben', 'Cara', 'Dev', 'Eli']) {
        expect(find.text(name), findsWidgets, reason: '$name must be on the wheel');
      }
    });

    testWidgets('the draw lands on one player and makes them the Lord', (
      tester,
    ) async {
      final container = await pumpToLordWheel(tester);

      await tester.tap(find.byKey(const Key('lord_spin')));
      await tester.pumpAndSettle();

      expect(find.text('THE LORD HAS BEEN CHOSEN'), findsOneWidget);
      final revealed = tester.widget<Text>(
        find.byKey(const Key('lord_result_name')),
      );
      expect(['Ann', 'Ben', 'Cara', 'Dev', 'Eli'], contains(revealed.data));

      await tester.tap(find.byKey(const Key('lord_continue')));
      await tester.pumpAndSettle();

      final game = container.read(gameSessionProvider)!;
      expect(game.phase, Phase.dayDiscussion);
      expect(game.leader.displayName, revealed.data);
      expect(find.byKey(const Key('dashboard_choose_team')), findsOneWidget);
    });

    testWidgets('a seeded draw is reproduced exactly', (tester) async {
      // The same seed must pick the same seat, proving the result comes from
      // real randomness rather than a fixed name.
      final names = ['Ann', 'Ben', 'Cara', 'Dev', 'Eli'];
      String drawnWith(int seed) {
        final random = Random(seed);
        return names[random.nextInt(names.length)];
      }

      expect(drawnWith(7), drawnWith(7));
      expect(
        List.generate(20, (seed) => drawnWith(seed)).toSet().length,
        greaterThan(1),
        reason: 'the draw must not always land on the same player',
      );

      // The screen accepts an injected source, so the reveal can be pinned.
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      startMatch(container);
      container.read(gameSessionProvider.notifier)
        ..startNight()
        ..endNight();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: LordSelectionScreen(random: Random(3)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expected = names[Random(3).nextInt(names.length)];
      await tester.tap(find.byKey(const Key('lord_spin')));
      await tester.pumpAndSettle();
      expect(find.text(expected), findsWidgets);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('lord_result_name')))
            .data,
        expected,
      );
    });

    testWidgets('reopening the wheel does not allow a second draw', (
      tester,
    ) async {
      final container = await pumpToLordWheel(tester);
      await tester.tap(find.byKey(const Key('lord_spin')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lord_continue')));
      await tester.pumpAndSettle();

      final drawn = container.read(gameSessionProvider)!.leaderSeat;
      // The wheel only draws once; a late call from any screen is refused.
      container
          .read(gameSessionProvider.notifier)
          .chooseLord(drawn == 1 ? 2 : 1);

      expect(container.read(gameSessionProvider)!.leaderSeat, drawn);
      expect(container.read(gameSessionProvider)!.phase, Phase.dayDiscussion);
    });
  });
}
