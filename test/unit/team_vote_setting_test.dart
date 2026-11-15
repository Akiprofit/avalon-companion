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

/// The team approval vote can be switched off in Settings. With it off, the
/// leader's team is the team: no tally, no rejection counter, and the round
/// still hands the leadership token on.
void main() {
  const names = ['Ann', 'Ben', 'Cara', 'Dev', 'Eli', 'Fay', 'Gus'];

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

  GameState newGame({int playerCount = 5}) => GameEngine.create(
    players: [
      for (var seat = 1; seat <= playerCount; seat++)
        Player(seat: seat, name: names[seat - 1]),
    ],
    composition: compositionFor(playerCount),
  );

  /// Night over and the first King drawn: the table sits in the first day.
  GameState firstDay({int playerCount = 5, int lordSeat = 1}) {
    var state = newGame(playerCount: playerCount);
    state = GameEngine.startNight(state);
    state = GameEngine.endNight(state);
    return GameEngine.chooseLord(state, seat: lordSeat);
  }

  GameState firstTeamSelection({int playerCount = 5, int lordSeat = 1}) =>
      GameEngine.beginTeamSelection(firstDay(
        playerCount: playerCount,
        lordSeat: lordSeat,
      ));

  /// The seats of the team the current quest requires, starting at seat 1.
  List<int> teamFor(GameState state) => [
    for (var seat = 1; seat <= state.requiredTeamSize; seat++) seat,
  ];

  test('with the vote off a confirmed team goes straight to the quest', () {
    final quest = GameEngine.proposeTeam(
      firstTeamSelection(),
      [1, 2],
      skipVote: true,
    );

    expect(quest.phase, Phase.questResolution);
    expect(quest.currentTeam, [1, 2]);
    expect(quest.approveVotes, 0);
    expect(quest.rejectVotes, 0);
    expect(quest.hasVotes, isFalse, reason: 'no tally was recorded');
    expect(quest.rejectionCount, 0);
    expect(quest.leaderSeat, 1, reason: 'the King is still the one leading');
  });

  test('with the vote on the same team still goes to the vote', () {
    final voting = GameEngine.proposeTeam(firstTeamSelection(), [1, 2]);

    expect(voting.phase, Phase.teamVoting);
    expect(voting.currentTeam, [1, 2]);
    expect(voting.hasVotes, isFalse);
  });

  test('the team size is checked exactly the same without a vote', () {
    final teamSelection = firstTeamSelection();

    expect(
      () => GameEngine.proposeTeam(teamSelection, [1], skipVote: true),
      throwsA(isA<GameRuleException>()),
      reason: 'quest 1 needs two players',
    );
    expect(
      () => GameEngine.proposeTeam(teamSelection, [1, 1], skipVote: true),
      throwsA(isA<GameRuleException>()),
      reason: 'a player cannot sit on the team twice',
    );
    expect(
      () => GameEngine.proposeTeam(teamSelection, [1, 9], skipVote: true),
      throwsA(isA<GameRuleException>()),
      reason: 'there is no seat 9 at a five-player table',
    );
  });

  test('without a vote the token passes on after the quest', () {
    var state = firstTeamSelection(lordSeat: 1);
    state = GameEngine.proposeTeam(state, [1, 2], skipVote: true);
    expect(state.leaderSeat, 1);

    state = GameEngine.recordQuest(state, failCards: 0, voteSkipped: true);

    expect(state.phase, Phase.dayDiscussion);
    expect(state.questNumber, 2);
    expect(
      state.leaderSeat,
      2,
      reason: 'the round hands the token on, exactly as a vote would',
    );
    expect(state.rejectionCount, 0);
  });

  test('the wheel still leaves the serving King out of its own draw', () {
    var state = firstTeamSelection(lordSeat: 3);
    state = GameEngine.proposeTeam(state, [1, 2], skipVote: true);
    state = GameEngine.recordQuest(
      state,
      failCards: 0,
      drawLord: true,
      voteSkipped: true,
    );

    expect(state.phase, Phase.lordSelection);
    expect(
      state.leaderSeat,
      3,
      reason: 'the draft keeps the King so the wheel can stand them down',
    );
    expect(
      GameEngine.drawableLordSeats(state),
      [1, 2, 4, 5],
      reason: 'the King who just served sits this draw out',
    );
  });

  test('a voteless match never counts a rejection', () {
    var state = firstDay();
    var rounds = 0;

    while (state.phase == Phase.dayDiscussion) {
      state = GameEngine.beginTeamSelection(state);
      state = GameEngine.proposeTeam(state, teamFor(state), skipVote: true);
      state = GameEngine.recordQuest(state, failCards: 0, voteSkipped: true);
      rounds++;

      expect(state.rejectionCount, 0, reason: 'nothing was ever rejected');
      expect(
        state.approveVotes + state.rejectVotes,
        0,
        reason: 'no tally is kept when the table does not vote',
      );
      expect(state.phase, isNot(Phase.evilVictory));
    }

    expect(rounds, 3, reason: 'three clean quests end the quest phase');
    expect(state.phase, Phase.assassination);
    expect(state.questFailures, 0);
    expect(state.questSuccesses, 3);
  });

  test('the controller carries the flag from Settings to the engine', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(gameSessionProvider.notifier);
    controller.start(names: names.take(5).toList(), composition: compositionFor(5));
    controller
      ..startNight()
      ..endNight()
      ..chooseLord(1)
      ..beginTeamSelection();

    controller.proposeTeam([1, 2], skipVote: true);

    final state = container.read(gameSessionProvider)!;
    expect(state.phase, Phase.questResolution);
    expect(state.hasVotes, isFalse);
    expect(state.rejectionCount, 0);
  });

  /// Plays the first three quests of a seven-player match as success, fail,
  /// success, so quest 4 is reached with both sides one away from victory.
  GameState walkToQuestFour() {
    var state = firstDay(playerCount: 7);
    const results = [0, 2, 0];

    for (final failCards in results) {
      state = GameEngine.beginTeamSelection(state);
      state = GameEngine.proposeTeam(state, teamFor(state), skipVote: true);
      state = GameEngine.recordQuest(
        state,
        failCards: failCards,
        voteSkipped: true,
      );
    }

    expect(state.phase, Phase.dayDiscussion);
    expect(state.questNumber, 4);
    return state;
  }

  test('a voteless quest still honours the two-fail rule on quest 4', () {
    final questFour = GameEngine.beginTeamSelection(walkToQuestFour());
    expect(questFour.failsRequired, 2);

    final oneFail = GameEngine.recordQuest(
      GameEngine.proposeTeam(questFour, teamFor(questFour), skipVote: true),
      failCards: 1,
    );
    expect(
      oneFail.questResults.last,
      QuestResult.success,
      reason: 'one fail card is not enough on quest 4 with 7+ players',
    );

    final twoFails = GameEngine.recordQuest(
      GameEngine.proposeTeam(questFour, teamFor(questFour), skipVote: true),
      failCards: 2,
    );
    expect(twoFails.questResults.last, QuestResult.fail);
  });
}
