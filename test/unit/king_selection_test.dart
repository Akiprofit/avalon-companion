import 'package:avalon_companion/game_engine/controllers/game_session_controller.dart';
import 'package:avalon_companion/game_engine/engine/game_engine.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/models/game_state.dart';
import 'package:avalon_companion/game_engine/models/phase.dart';
import 'package:avalon_companion/game_engine/models/player.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The King selection setting: with "New King every round" the table returns to
/// the wheel after every proposal, and a player never leads twice in a row
/// while somebody else can lead.
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

  /// The night and the first draw, so the table sits in the first day.
  void startFirstRound(ProviderContainer container, {int lordSeat = 2}) {
    container.read(gameSessionProvider.notifier)
      ..startNight()
      ..endNight()
      ..chooseLord(lordSeat);
  }

  GameState game(ProviderContainer container) =>
      container.read(gameSessionProvider)!;

  /// One full round: an approved team, the cards, and the hand-over.
  void playRound(
    ProviderContainer container, {
    required bool drawLord,
    int failCards = 0,
  }) {
    final controller = container.read(gameSessionProvider.notifier);
    final size = game(container).requiredTeamSize;
    controller.beginTeamSelection();
    controller.proposeTeam([for (var seat = 1; seat <= size; seat++) seat]);
    controller.recordVotes(approve: game(container).playerCount, reject: 0);
    controller.resolveTeamVote(drawLord: drawLord);
    controller.recordQuest(failCards: failCards, drawLord: drawLord);
  }

  test('the first draw of a match takes the whole table', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    startMatch(container);
    container.read(gameSessionProvider.notifier)
      ..startNight()
      ..endNight();

    expect(game(container).phase, Phase.lordSelection);
    expect(GameEngine.drawableLordSeats(game(container)), [1, 2, 3, 4, 5]);
  });

  test('automatic mode returns to the wheel after every quest', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    startMatch(container);
    startFirstRound(container, lordSeat: 2);

    playRound(container, drawLord: true);

    final afterQuest = game(container);
    expect(afterQuest.phase, Phase.lordSelection);
    expect(afterQuest.questNumber, 2);
    expect(
      afterQuest.leaderSeat,
      2,
      reason: 'the King who just served stays put until the wheel lands',
    );
    expect(
      GameEngine.drawableLordSeats(afterQuest),
      [1, 3, 4, 5],
      reason: 'nobody leads twice in a row while others can lead',
    );

    container.read(gameSessionProvider.notifier).chooseLord(3);
    expect(game(container).phase, Phase.dayDiscussion);
    expect(game(container).leaderSeat, 3);
    expect(game(container).questNumber, 2, reason: 'the round is not repeated');

    playRound(container, drawLord: true);
    expect(game(container).phase, Phase.lordSelection);
    expect(GameEngine.drawableLordSeats(game(container)), [1, 2, 4, 5]);
  });

  test('a rejected proposal draws a new King in automatic mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    startMatch(container);
    startFirstRound(container, lordSeat: 4);

    final controller = container.read(gameSessionProvider.notifier);
    controller.beginTeamSelection();
    controller.proposeTeam([1, 2]);
    controller.recordVotes(approve: 0, reject: 5);
    controller.resolveTeamVote(drawLord: true);

    expect(game(container).phase, Phase.lordSelection);
    expect(game(container).rejectionCount, 1);
    expect(game(container).currentTeam, isEmpty);
    expect(GameEngine.drawableLordSeats(game(container)), [1, 2, 3, 5]);

    controller.chooseLord(5);
    expect(game(container).phase, Phase.dayDiscussion);
    expect(game(container).leaderSeat, 5);
    expect(
      game(container).rejectionCount,
      1,
      reason: 'the fifth rejection still ends the match for Evil',
    );
  });

  test('manual mode keeps the leadership token in seating order', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    startMatch(container);
    startFirstRound(container, lordSeat: 2);

    playRound(container, drawLord: false);

    expect(game(container).phase, Phase.dayDiscussion);
    expect(game(container).leaderSeat, 3);
  });

  test('the wheel opens on demand between rounds, never mid-vote', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    startMatch(container);
    startFirstRound(container, lordSeat: 1);

    // One round played: the second round is under way and the token sits on
    // seat 2, the King who has just served.
    playRound(container, drawLord: false);
    expect(game(container).phase, Phase.dayDiscussion);
    expect(game(container).questNumber, 2);

    final controller = container.read(gameSessionProvider.notifier);
    controller.beginLordDraw();
    expect(game(container).phase, Phase.lordSelection);
    expect(GameEngine.drawableLordSeats(game(container)), [1, 3, 4, 5]);

    controller.chooseLord(4);
    controller.beginTeamSelection();
    controller.proposeTeam([1, 2, 3]);
    expect(game(container).phase, Phase.teamVoting);

    controller.beginLordDraw();
    expect(
      game(container).phase,
      Phase.teamVoting,
      reason: 'a draw must never interrupt a running tally',
    );

    expect(
      () => GameEngine.beginLordDraw(game(container)),
      throwsA(isA<GameRuleException>()),
    );
  });

  test('a single eligible player is still drawn', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    startMatch(container);
    final players = game(container).players;
    final solo = game(container).copyWith(
      players: [players.first],
      leaderSeat: players.first.seat,
      questNumber: 2,
    );

    expect(GameEngine.drawableLordSeats(solo), [players.first.seat]);
  });

  test('Play Again clears the draw history but keeps the roster', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    startMatch(container);
    startFirstRound(container, lordSeat: 3);

    final controller = container.read(gameSessionProvider.notifier);
    for (var round = 0; round < 3; round++) {
      playRound(container, drawLord: true);
      final seats = GameEngine.drawableLordSeats(game(container));
      controller.chooseLord(seats.first);
    }
    controller.resolveAssassination(merlinIdentified: false);
    expect(game(container).phase, Phase.goodVictory);

    controller.playAgain();
    final replay = game(container);
    expect(replay.phase, Phase.preparation);
    expect(replay.players.map((p) => p.name), ['Ann', 'Ben', 'Cara', 'Dev', 'Eli']);
    expect(replay.players.map((p) => p.seat), [1, 2, 3, 4, 5]);
    expect(replay.questResults, isEmpty);
    expect(replay.rejectionCount, 0);

    controller
      ..startNight()
      ..endNight();
    expect(
      GameEngine.drawableLordSeats(game(container)),
      [1, 2, 3, 4, 5],
      reason: 'a new match starts with a clean draw',
    );
  });

  test('drawing never invents or drops a player', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    startMatch(container);
    startFirstRound(container, lordSeat: 1);

    final controller = container.read(gameSessionProvider.notifier);
    for (var round = 0; round < 2; round++) {
      playRound(container, drawLord: true);
      controller.chooseLord(GameEngine.drawableLordSeats(game(container)).last);
    }

    final players = game(container).players;
    expect(players, hasLength(5));
    expect(players.map((p) => p.seat).toSet(), {1, 2, 3, 4, 5});
    expect(players.map((p) => p.name).toSet(), {
      'Ann',
      'Ben',
      'Cara',
      'Dev',
      'Eli',
    });
  });

  test('a draw is refused outside the wheel', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    startMatch(container);
    startFirstRound(container, lordSeat: 1);

    final before = game(container);
    container.read(gameSessionProvider.notifier).chooseLord(3);

    expect(game(container), same(before));
    expect(game(container).leaderSeat, 1);
  });

  test('the engine keeps the whole table for a one-seat draw', () {
    // Guard for the "only one player" rule: the draw must not divide by zero
    // or return an empty list.
    final solo = GameState(
      players: const [Player(seat: 1, name: 'Ann')],
      composition: Composition(playerCount: 1, counts: const {}),
      phase: Phase.lordSelection,
      leaderSeat: 1,
      questNumber: 2,
      rejectionCount: 0,
      questResults: const [],
      currentTeam: const [],
      startedAt: DateTime(2026),
    );

    expect(GameEngine.drawableLordSeats(solo), [1]);
    expect(GameEngine.chooseLord(solo, seat: 1).leaderSeat, 1);
  });
}
