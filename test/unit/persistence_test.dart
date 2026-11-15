import 'package:avalon_companion/database/database_provider.dart';
import 'package:avalon_companion/database/match_store.dart';
import 'package:avalon_companion/game_engine/controllers/game_session_controller.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/models/game_state.dart';
import 'package:avalon_companion/game_engine/models/phase.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_match_store.dart';

/// Phase 9 gate: a match is written as it is played, restored when the app comes
/// back, and never blocked by a storage failure.
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

  ProviderContainer containerWith(FakeMatchStore store, {StoredMatch? restored}) {
    final container = ProviderContainer(
      overrides: [
        matchStoreProvider.overrideWithValue(store),
        restoredMatchProvider.overrideWithValue(restored),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  GameSessionController startMatch(
    ProviderContainer container, {
    List<String> names = const ['Ann', 'Ben', 'Cara', 'Dev', 'Eli'],
  }) {
    final controller = container.read(gameSessionProvider.notifier);
    controller.start(names: names, composition: compositionFor(names.length));
    return controller;
  }

  /// Runs the whole match to a Good victory.
  Future<void> playToVictory(GameSessionController controller) async {
    controller.startNight();
    controller.endNight();
    controller.chooseLord(2);
    for (var quest = 0; quest < 3; quest++) {
      controller.beginTeamSelection();
      final game = controller.state!;
      controller.proposeTeam([
        for (var seat = 1; seat <= game.requiredTeamSize; seat++) seat,
      ]);
      controller.recordVotes(approve: 4, reject: 1);
      controller.resolveTeamVote();
      controller.recordQuest(failCards: 0);
    }
    controller.resolveAssassination(merlinIdentified: false);
    await controller.writesSettled;
  }

  group('writing a match as it is played', () {
    test('the first snapshot is created once, then updated in place', () async {
      final store = FakeMatchStore();
      final container = containerWith(store);

      final controller = startMatch(container);
      await controller.writesSettled;

      expect(store.created.length, 1);
      final id = store.created.keys.single;
      expect(store.created[id]!.phase, Phase.preparation);
      expect(store.created[id]!.players.map((p) => p.name), [
        'Ann',
        'Ben',
        'Cara',
        'Dev',
        'Eli',
      ]);

      controller.startNight();
      controller.endNight();
      controller.chooseLord(3);
      await controller.writesSettled;

      expect(store.created.length, 1, reason: 'never a second row');
      expect(store.saved.map((s) => s.phase), [
        Phase.night,
        Phase.lordSelection,
        Phase.dayDiscussion,
      ]);
      expect(store.saved.last.leaderSeat, 3);
      expect(store.events.single, contains('lordDrawn: The wheel drew'));
    });

    test('a resolved vote is written with its seats and counts', () async {
      final store = FakeMatchStore();
      final container = containerWith(store);
      final controller = startMatch(container);
      controller.startNight();
      controller.endNight();
      controller.chooseLord(1);
      controller.beginTeamSelection();
      controller.proposeTeam([1, 2]);
      controller.recordVotes(approve: 3, reject: 2);
      controller.resolveTeamVote();
      await controller.writesSettled;

      expect(store.proposals.length, 1);
      final proposal = store.proposals.single;
      expect(proposal.questNumber, 1);
      expect(proposal.leaderSeat, 1);
      expect(proposal.seats, [1, 2]);
      expect(proposal.approve, 3);
      expect(proposal.reject, 2);
      expect(proposal.verdict, TeamVerdict.approved);
      expect(controller.state!.phase, Phase.questResolution);
    });

    test('a rejected vote is written as rejected and rotates the Lord', () async {
      final store = FakeMatchStore();
      final container = containerWith(store);
      final controller = startMatch(container);
      controller.startNight();
      controller.endNight();
      controller.chooseLord(1);
      controller.beginTeamSelection();
      controller.proposeTeam([1, 2]);
      controller.recordVotes(approve: 1, reject: 4);
      controller.resolveTeamVote();
      await controller.writesSettled;

      expect(store.proposals.single.verdict, TeamVerdict.rejected);
      expect(controller.state!.phase, Phase.dayDiscussion);
      expect(controller.state!.leaderSeat, 2);
      expect(controller.state!.rejectionCount, 1);
    });

    test('a resolved quest is written with its score', () async {
      final store = FakeMatchStore();
      final container = containerWith(store);
      final controller = startMatch(container);
      controller.startNight();
      controller.endNight();
      controller.chooseLord(1);
      controller.beginTeamSelection();
      controller.proposeTeam([1, 2]);
      controller.recordVotes(approve: 5, reject: 0);
      controller.resolveTeamVote();
      controller.recordQuest(failCards: 1);
      await controller.writesSettled;

      expect(store.quests.length, 1);
      final quest = store.quests.single;
      expect(quest.questNumber, 1);
      expect(quest.requiredPlayers, 2);
      expect(quest.failCards, 1);
      expect(quest.result, QuestResult.fail, reason: 'one fail sinks quest 1');
      expect(store.saved.last.questResults, [QuestResult.fail]);
    });

    test('a finished match records the result and the accusation outcome',
        () async {
      final store = FakeMatchStore();
      final container = containerWith(store);
      final controller = startMatch(container);
      await playToVictory(controller);

      expect(controller.state!.phase, Phase.goodVictory);
      expect(store.saved.last.isFinished, isTrue);
      expect(store.saved.last.merlinIdentified, isFalse);
      expect(store.quests.length, 3);
      expect(store.proposals.length, 3);
      expect(
        store.events.any((e) => e.startsWith('matchEnded: Good won')),
        isTrue,
      );
      expect(
        store.events.join(' '),
        isNot(contains('Ann')),
        reason: 'the log never names a player',
      );
    });
  });

  group('ending a match', () {
    test('aborting marks the row abandoned without deleting it', () async {
      final store = FakeMatchStore();
      final container = containerWith(store);
      final controller = startMatch(container);
      controller.startNight();
      await controller.writesSettled;
      final id = store.created.keys.single;

      controller.abort();
      await controller.writesSettled;

      expect(controller.state, isNull);
      expect(store.abandoned, [id]);
    });

    test('starting a new match abandons the running one first', () async {
      final store = FakeMatchStore();
      final container = containerWith(store);
      final controller = startMatch(container);
      await controller.writesSettled;
      final first = store.created.keys.single;

      controller.abort();
      startMatch(container);
      await container.read(gameSessionProvider.notifier).writesSettled;

      expect(store.abandoned, [first]);
      expect(store.created.length, 2);
    });

    test('Play Again writes a second row and keeps the first result intact',
        () async {
      final store = FakeMatchStore();
      final container = containerWith(store);
      final controller = startMatch(container);
      await playToVictory(controller);

      final first = store.created.keys.single;
      final firstResult = store.created[first]!;
      final finishedSave = store.saved.last;
      expect(finishedSave.isFinished, isTrue);

      controller.playAgain();
      await controller.writesSettled;

      expect(store.created.length, 2, reason: 'a brand-new row per match');
      expect(store.abandoned, isEmpty, reason: 'the old match was finished');
      final second = store.created.keys.last;
      expect(second, isNot(first));
      expect(store.created[second]!.phase, Phase.preparation);
      expect(store.created[second]!.questResults, isEmpty);
      expect(
        store.created[second]!.players.map((p) => p.name),
        firstResult.players.map((p) => p.name),
      );
      expect(
        finishedSave.phase,
        Phase.goodVictory,
        reason: 'the old row keeps its result',
      );
    });
  });

  group('recovery on launch', () {
    test('a stored match is restored with its row id', () async {
      final store = FakeMatchStore();
      final probe = ProviderContainer();
      addTearDown(probe.dispose);
      final controllerProbe = probe.read(gameSessionProvider.notifier);
      controllerProbe.start(
        names: const ['Ann', 'Ben', 'Cara', 'Dev', 'Eli'],
        composition: compositionFor(5),
      );
      final state = controllerProbe.state!;

      final container = containerWith(
        store,
        restored: StoredMatch(id: 42, state: state),
      );

      final restored = container.read(gameSessionProvider);
      expect(restored, same(state));

      container.read(gameSessionProvider.notifier).startNight();
      await container.read(gameSessionProvider.notifier).writesSettled;

      expect(store.created, isEmpty, reason: 'the row already exists');
      expect(store.saved.single.phase, Phase.night);
      expect(store.saved.length, 1);
    });

    test('no stored match means an empty table, not an error', () {
      final container = containerWith(FakeMatchStore());
      expect(container.read(gameSessionProvider), isNull);
    });
  });

  group('storage is optional', () {
    test('a match runs with no store at all', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = startMatch(container);

      await playToVictory(controller);

      expect(container.read(gameSessionProvider)!.phase, Phase.goodVictory);
    });

    test('a broken disk never stops the match', () async {
      // Throwing on the very first write is the worst case: no row id is ever
      // assigned, so every later write is skipped instead of failing the game.
      final store = FakeMatchStore()..broken = true;
      final container = containerWith(store);
      final controller = startMatch(container);
      await controller.writesSettled;

      controller.startNight();
      controller.endNight();
      controller.chooseLord(1);
      await controller.writesSettled;

      expect(container.read(gameSessionProvider)!.phase, Phase.dayDiscussion);
      expect(container.read(gameSessionProvider)!.leaderSeat, 1);
      expect(store.created, isEmpty);
    });
  });
}
