import 'package:avalon_companion/game_engine/engine/game_engine.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/models/game_state.dart';
import 'package:avalon_companion/game_engine/models/phase.dart';
import 'package:avalon_companion/game_engine/models/player.dart';
import 'package:avalon_companion/game_engine/models/quest_slot.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:flutter_test/flutter_test.dart';

/// ---- helpers -------------------------------------------------------------

List<Player> _seats(int count) => [
  for (var i = 1; i <= count; i++) Player(seat: i, name: 'P$i'),
];

Composition _defaultComposition(int playerCount) {
  final defaults = AvalonTables.defaultComposition(playerCount);
  final counts = <Character, int>{};
  for (final character in Character.values) {
    final value = defaults[character.label];
    if (value != null && value > 0) counts[character] = value;
  }
  return Composition(playerCount: playerCount, counts: counts);
}

GameState _newGame({int players = 5}) => GameEngine.create(
  players: _seats(players),
  composition: _defaultComposition(players),
  startedAt: DateTime(2026, 1, 1),
);

/// Prepares a game at [Phase.teamSelection] for the current quest.
GameState _toTeamSelection(GameState state) => GameEngine.beginTeamSelection(
  GameEngine.chooseLord(
    GameEngine.endNight(GameEngine.startNight(state)),
    seat: 1,
  ),
);

/// Proposes and votes on a team, returning the state right after the vote.
GameState _vote(GameState state, List<int> team, {required int approve}) {
  final proposed = GameEngine.proposeTeam(state, team);
  final recorded = GameEngine.recordVotes(
    proposed,
    approve: approve,
    reject: state.playerCount - approve,
  );
  return GameEngine.resolveTeamVote(recorded);
}

/// Runs one full quest: propose, approve unanimously, resolve with [failCards].
GameState _playQuest(GameState state, {int failCards = 0}) {
  final ready = switch (state.phase) {
    Phase.preparation => _toTeamSelection(state),
    Phase.lordSelection => GameEngine.beginTeamSelection(
      GameEngine.chooseLord(state, seat: 1),
    ),
    Phase.dayDiscussion => GameEngine.beginTeamSelection(state),
    Phase.teamSelection => state,
    _ => throw StateError('A quest cannot start from ${state.phase}.'),
  };
  final team = ready.players
      .take(ready.requiredTeamSize)
      .map((p) => p.seat)
      .toList();
  final voted = _vote(ready, team, approve: ready.playerCount);
  return GameEngine.recordQuest(voted, failCards: failCards);
}

/// Rejects the same proposal five times in a row.
GameState _fiveRejections(GameState state) {
  var current = _toTeamSelection(state);
  for (var i = 0; i < 5; i++) {
    final team = current.players
        .take(current.requiredTeamSize)
        .map((p) => p.seat)
        .toList();
    current = _vote(current, team, approve: 0);
    if (current.phase == Phase.dayDiscussion) {
      current = GameEngine.beginTeamSelection(current);
    }
  }
  return current;
}

void main() {
  group('create', () {
    test('starts in preparation with the first seat leading', () {
      final game = _newGame(players: 7);

      expect(game.phase, Phase.preparation);
      expect(game.playerCount, 7);
      expect(game.leaderSeat, 1);
      expect(game.questNumber, 1);
      expect(game.rejectionCount, 0);
      expect(game.questResults, isEmpty);
      expect(game.currentTeam, isEmpty);
      expect(game.isFinished, isFalse);
      expect(game.merlinIdentified, isNull);
    });

    test('players are stored in seat order and are immutable', () {
      final shuffled = [
        const Player(seat: 3, name: 'C'),
        const Player(seat: 1, name: 'A'),
        const Player(seat: 2, name: 'B'),
        const Player(seat: 4, name: 'D'),
        const Player(seat: 5, name: 'E'),
      ];
      final game = GameEngine.create(
        players: shuffled,
        composition: _defaultComposition(5),
      );

      expect(game.players.map((p) => p.seat), [1, 2, 3, 4, 5]);
      expect(() => game.players.add(const Player(seat: 6, name: 'F')),
          throwsA(isA<UnsupportedError>()));
      expect(() => game.questResults.add(QuestResult.success),
          throwsA(isA<UnsupportedError>()));
    });

    test('rejects fewer than 5 or more than 10 players', () {
      expect(
        () => GameEngine.create(
          players: _seats(4),
          composition: _defaultComposition(4),
        ),
        throwsA(isA<GameRuleException>()),
      );
      expect(
        () => GameEngine.create(
          players: _seats(11),
          composition: _defaultComposition(10),
        ),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('rejects a composition built for a different seat count', () {
      expect(
        () => GameEngine.create(
          players: _seats(5),
          composition: _defaultComposition(6),
        ),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('rejects a composition with the wrong good/evil split', () {
      final broken = Composition(
        playerCount: 5,
        counts: const {
          Character.merlin: 1,
          Character.loyalServant: 3,
          Character.assassin: 1,
          Character.morgana: 1,
        },
      );

      expect(
        () => GameEngine.create(players: _seats(5), composition: broken),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('rejects two players sharing a seat', () {
      final duplicated = [
        const Player(seat: 1, name: 'A'),
        const Player(seat: 1, name: 'B'),
        const Player(seat: 2, name: 'C'),
        const Player(seat: 3, name: 'D'),
        const Player(seat: 4, name: 'E'),
      ];

      expect(
        () => GameEngine.create(
          players: duplicated,
          composition: _defaultComposition(5),
        ),
        throwsA(isA<GameRuleException>()),
      );
    });
  });

  group('phase transitions', () {
    test('preparation -> night -> the Lord draw -> day -> team selection', () {
      var game = _newGame();

      game = GameEngine.startNight(game);
      expect(game.phase, Phase.night);

      game = GameEngine.endNight(game);
      expect(game.phase, Phase.lordSelection);

      game = GameEngine.chooseLord(game, seat: 3);
      expect(game.phase, Phase.dayDiscussion);
      expect(game.leaderSeat, 3);

      game = GameEngine.beginTeamSelection(game);
      expect(game.phase, Phase.teamSelection);
    });

    test('the Lord draw refuses an empty seat and a second draw', () {
      final draw = GameEngine.endNight(GameEngine.startNight(_newGame()));

      expect(
        () => GameEngine.chooseLord(draw, seat: 9),
        throwsA(isA<GameRuleException>()),
      );
      expect(
        () => GameEngine.chooseLord(_newGame(), seat: 1),
        throwsA(isA<GameRuleException>()),
        reason: 'the draw only happens after the night',
      );

      final day = GameEngine.chooseLord(draw, seat: 2);
      expect(day.leaderSeat, 2);
      expect(
        () => GameEngine.chooseLord(day, seat: 4),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('illegal transitions throw', () {
      final game = _newGame();

      expect(() => GameEngine.endNight(game), throwsA(isA<GameRuleException>()));
      expect(() => GameEngine.beginTeamSelection(game),
          throwsA(isA<GameRuleException>()));
      expect(
        () => GameEngine.proposeTeam(game, [1, 2]),
        throwsA(isA<GameRuleException>()),
      );
      expect(
        () => GameEngine.recordVotes(game, approve: 5, reject: 0),
        throwsA(isA<GameRuleException>()),
      );
      expect(() => GameEngine.resolveTeamVote(game),
          throwsA(isA<GameRuleException>()));
      expect(() => GameEngine.recordQuest(game, failCards: 0),
          throwsA(isA<GameRuleException>()));
      expect(
        () => GameEngine.resolveAssassination(game, merlinIdentified: false),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('night cannot be started twice', () {
      final night = GameEngine.startNight(_newGame());

      expect(() => GameEngine.startNight(night), throwsA(isA<GameRuleException>()));
    });
  });

  group('team proposal', () {
    for (final players in [5, 6, 7, 8, 9, 10]) {
      test('$players players must propose the table team size per quest', () {
        var game = _toTeamSelection(_newGame(players: players));
        final sizes = AvalonTables.questSizes(players);
        var successes = 0;
        var failures = 0;

        for (var quest = 1; quest <= 3; quest++) {
          final size = sizes[quest - 1];
          expect(game.requiredTeamSize, size);

          // Every wrong size is refused.
          for (final delta in [-1, 1]) {
            final wrong = size + delta;
            if (wrong < 1 || wrong > players) continue;
            expect(
              () => GameEngine.proposeTeam(
                game,
                game.players.take(wrong).map((p) => p.seat).toList(),
              ),
              throwsA(isA<GameRuleException>()),
            );
          }

          final failCards = quest.isEven ? size : 0;
          game = _playQuest(game, failCards: failCards);
          if (quest.isEven) {
            failures++;
          } else {
            successes++;
          }
          game = GameEngine.beginTeamSelection(game);
        }

        expect(successes, 2);
        expect(failures, 1);
      });
    }

    test('duplicate seats are refused', () {
      final game = _toTeamSelection(_newGame(players: 5));

      expect(
        () => GameEngine.proposeTeam(game, [1, 1]),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('seats that do not exist are refused', () {
      final game = _toTeamSelection(_newGame(players: 5));

      expect(
        () => GameEngine.proposeTeam(game, [1, 9]),
        throwsA(isA<GameRuleException>()),
      );
      expect(
        () => GameEngine.proposeTeam(game, [0, 1]),
        throwsA(isA<GameRuleException>()),
      );
    });
  });

  group('voting', () {
    test('vote totals must add up to every player', () {
      final voting = GameEngine.proposeTeam(_toTeamSelection(_newGame()), [1, 2]);

      expect(
        () => GameEngine.recordVotes(voting, approve: 2, reject: 2),
        throwsA(isA<GameRuleException>()),
      );
      expect(
        () => GameEngine.recordVotes(voting, approve: 6, reject: 0),
        throwsA(isA<GameRuleException>()),
      );
      expect(
        () => GameEngine.recordVotes(voting, approve: -1, reject: 6),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('a team cannot be resolved before every vote is recorded', () {
      final voting = GameEngine.proposeTeam(_toTeamSelection(_newGame()), [1, 2]);

      // A fresh proposal has no votes at all.
      expect(() => GameEngine.resolveTeamVote(voting),
          throwsA(isA<GameRuleException>()));

      // A total that does not account for every player is refused.
      expect(
        () => GameEngine.recordVotes(voting, approve: 1, reject: 1),
        throwsA(isA<GameRuleException>()),
      );

      final complete = GameEngine.recordVotes(voting, approve: 3, reject: 2);
      expect(GameEngine.resolveTeamVote(complete).phase, Phase.questResolution);
    });

    test('a strict majority approves', () {
      for (final players in [5, 6, 7, 8, 9, 10]) {
        final team = [
          for (var i = 1; i <= AvalonTables.teamSize(players, 1); i++) i,
        ];
        final voting = GameEngine.proposeTeam(
          _toTeamSelection(_newGame(players: players)),
          team,
        );
        final approve = players ~/ 2 + 1;
        final resolved = GameEngine.resolveTeamVote(
          GameEngine.recordVotes(
            voting,
            approve: approve,
            reject: players - approve,
          ),
        );

        expect(resolved.phase, Phase.questResolution,
            reason: '$approve of $players should approve');
      }
    });

    test('a tie or a minority rejects', () {
      final voting = GameEngine.proposeTeam(_toTeamSelection(_newGame()), [1, 2]);

      for (final approve in [0, 1, 2]) {
        final resolved = GameEngine.resolveTeamVote(
          GameEngine.recordVotes(voting, approve: approve, reject: 5 - approve),
        );
        expect(resolved.phase, Phase.dayDiscussion,
            reason: '$approve of 5 should not approve');
      }
    });

    test('an approved team advances to the quest and clears the rejection counter',
        () {
      var game = _toTeamSelection(_newGame());

      // Two rejections first.
      for (var i = 0; i < 2; i++) {
        game = _vote(game, [1, 2], approve: 0);
        game = GameEngine.beginTeamSelection(game);
      }
      expect(game.rejectionCount, 2);

      final approved = _vote(game, [1, 2], approve: 5);
      expect(approved.phase, Phase.questResolution);
      expect(approved.rejectionCount, 0);
      expect(approved.currentTeam, [1, 2]);
    });

    test('the leader token rotates after every resolved proposal', () {
      var game = _toTeamSelection(_newGame());
      expect(game.leaderSeat, 1);

      // A rejection advances the token.
      game = _vote(game, [1, 2], approve: 0);
      expect(game.leaderSeat, 2);

      // An approval advances it too.
      game = GameEngine.beginTeamSelection(game);
      game = _vote(game, [2, 3], approve: 5);
      expect(game.leaderSeat, 3);
    });

    test('the token wraps from the last seat to the first', () {
      var game = _newGame();
      // Move the token to the last seat by rejecting once per seat.
      game = _toTeamSelection(game);
      for (var i = 0; i < game.playerCount - 1; i++) {
        game = _vote(game, [1, 2], approve: 0);
        game = GameEngine.beginTeamSelection(game);
      }
      expect(game.leaderSeat, 5);

      game = _vote(game, [1, 2], approve: 0);
      expect(game.leaderSeat, 1);
    });

    test('five rejections in a row win the match for evil', () {
      final game = _fiveRejections(_newGame());

      expect(game.phase, Phase.evilVictory);
      expect(game.rejectionCount, 5);
      expect(game.isFinished, isTrue);
      expect(game.finishedAt, isNotNull);
    });

    test('a rejection returns to discussion with a clean proposal', () {
      final rejected = _vote(_toTeamSelection(_newGame()), [1, 2], approve: 0);

      expect(rejected.phase, Phase.dayDiscussion);
      expect(rejected.currentTeam, isEmpty);
      expect(rejected.approveVotes, 0);
      expect(rejected.rejectVotes, 0);
      expect(rejected.rejectionCount, 1);
      expect(rejected.questResults, isEmpty);
    });
  });

  group('quest resolution', () {
    test('one fail card fails a quest', () {
      final resolved = _playQuest(_toTeamSelection(_newGame()), failCards: 1);

      expect(resolved.questFailures, 1);
      expect(resolved.questSuccesses, 0);
      expect(resolved.questNumber, 2);
    });

    test('zero fail cards succeeds', () {
      final resolved = _playQuest(_toTeamSelection(_newGame()));

      expect(resolved.questSuccesses, 1);
      expect(resolved.questNumber, 2);
    });

    test('quest 4 needs two fail cards with 7 or more players', () {
      final game = _toTeamSelection(_newGame(players: 7));
      expect(AvalonTables.failsRequired(7, 4), 2);

      // Reach quest 4 with two successes and one failure but not three of any.
      var current = _playQuest(game);
      current = _playQuest(GameEngine.beginTeamSelection(current), failCards: 1);
      current = _playQuest(GameEngine.beginTeamSelection(current));
      current = GameEngine.beginTeamSelection(current);
      expect(current.questNumber, 4);
      expect(current.failsRequired, 2);

      // A single fail card does not fail quest 4.
      final oneFail = _playQuest(current, failCards: 1);
      expect(oneFail.questSuccesses, 3);
      expect(oneFail.questResults.last, QuestResult.success);

      // Two fail cards do.
      final twoFails = _playQuest(current, failCards: 2);
      expect(twoFails.questResults.last, QuestResult.fail);
    });

    test('quest 4 still needs only one fail card below 7 players', () {
      expect(AvalonTables.failsRequired(5, 4), 1);
      expect(AvalonTables.failsRequired(6, 4), 1);
      expect(AvalonTables.failsRequired(7, 4), 2);

      var current = _toTeamSelection(_newGame(players: 6));
      current = _playQuest(current);
      current = _playQuest(GameEngine.beginTeamSelection(current), failCards: 1);
      current = _playQuest(GameEngine.beginTeamSelection(current));
      current = GameEngine.beginTeamSelection(current);
      expect(current.questNumber, 4);

      final oneFail = _playQuest(current, failCards: 1);
      expect(oneFail.questResults.last, QuestResult.fail);
    });

    test('a resolved quest cannot be recorded twice', () {
      final resolved = _playQuest(_toTeamSelection(_newGame()));

      expect(
        () => GameEngine.recordQuest(resolved, failCards: 0),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('more fail cards than team members is impossible', () {
      final voting = _vote(_toTeamSelection(_newGame()), [1, 2], approve: 5);

      expect(
        () => GameEngine.recordQuest(voting, failCards: 3),
        throwsA(isA<GameRuleException>()),
      );
      expect(
        () => GameEngine.recordQuest(voting, failCards: -1),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('quest slots follow the recorded results', () {
      final resolved = _playQuest(_toTeamSelection(_newGame()), failCards: 1);

      expect(resolved.questSlots, [
        QuestSlot.fail,
        QuestSlot.current,
        QuestSlot.pending,
        QuestSlot.pending,
        QuestSlot.pending,
      ]);
    });

    test('three successes hand the match to the assassination', () {
      var game = _toTeamSelection(_newGame());

      for (var i = 0; i < 3; i++) {
        game = _playQuest(game);
        if (i < 2) game = GameEngine.beginTeamSelection(game);
      }

      expect(game.phase, Phase.assassination);
      expect(game.questSuccesses, 3);
      expect(game.isFinished, isFalse);
      expect(game.merlinIdentified, isNull);
    });

    test('three failures win the match for evil', () {
      var game = _toTeamSelection(_newGame());

      for (var i = 0; i < 3; i++) {
        game = _playQuest(game, failCards: 1);
        if (i < 2) game = GameEngine.beginTeamSelection(game);
      }

      expect(game.phase, Phase.evilVictory);
      expect(game.questFailures, 3);
      expect(game.isFinished, isTrue);
    });
  });

  group('assassination', () {
    GameState atAssassination() {
      var game = _toTeamSelection(_newGame());
      for (var i = 0; i < 3; i++) {
        game = _playQuest(game);
        if (i < 2) game = GameEngine.beginTeamSelection(game);
      }
      return game;
    }

    test('an identified Merlin wins for evil', () {
      final resolved =
          GameEngine.resolveAssassination(atAssassination(), merlinIdentified: true);

      expect(resolved.phase, Phase.evilVictory);
      expect(resolved.merlinIdentified, isTrue);
      expect(resolved.isFinished, isTrue);
    });

    test('a missed accusation wins for good', () {
      final resolved =
          GameEngine.resolveAssassination(atAssassination(), merlinIdentified: false);

      expect(resolved.phase, Phase.goodVictory);
      expect(resolved.merlinIdentified, isFalse);
      expect(resolved.isFinished, isTrue);
    });

    test('the outcome is a flag, not a target', () {
      final resolved =
          GameEngine.resolveAssassination(atAssassination(), merlinIdentified: true);

      // Nothing in the state records who was named: seats are players only.
      expect(resolved.players.map((p) => p.seat), [1, 2, 3, 4, 5]);
      expect(resolved.merlinIdentified, isTrue);
    });

    test('the accusation cannot be resolved twice', () {
      final resolved =
          GameEngine.resolveAssassination(atAssassination(), merlinIdentified: false);

      expect(
        () => GameEngine.resolveAssassination(resolved, merlinIdentified: true),
        throwsA(isA<GameRuleException>()),
      );
    });
  });

  group('pause and finish', () {
    test('pause remembers the interrupted phase and resume restores it', () {
      final night = GameEngine.startNight(_newGame());
      final paused = GameEngine.pause(night);

      expect(paused.phase, Phase.paused);
      expect(paused.pausedFrom, Phase.night);

      final resumed = GameEngine.resume(paused);
      expect(resumed.phase, Phase.night);
      expect(resumed.pausedFrom, isNull);
    });

    test('a paused match rejects game commands until resumed', () {
      final paused = GameEngine.pause(GameEngine.startNight(_newGame()));

      expect(() => GameEngine.endNight(paused), throwsA(isA<GameRuleException>()));
      expect(GameEngine.resume(paused).phase, Phase.night);
    });

    test('pausing twice or resuming a running match throws', () {
      final paused = GameEngine.pause(_newGame());

      expect(() => GameEngine.pause(paused), throwsA(isA<GameRuleException>()));
      expect(() => GameEngine.resume(_newGame()), throwsA(isA<GameRuleException>()));
    });

    test('nothing is playable after either victory', () {
      final good = GameEngine.resolveAssassination(
        (() {
          var game = _toTeamSelection(_newGame());
          for (var i = 0; i < 3; i++) {
            game = _playQuest(game);
            if (i < 2) game = GameEngine.beginTeamSelection(game);
          }
          return game;
        })(),
        merlinIdentified: false,
      );
      expect(good.phase, Phase.goodVictory);

      expect(() => GameEngine.pause(good), throwsA(isA<GameRuleException>()));
      expect(() => GameEngine.proposeTeam(good, [1, 2]),
          throwsA(isA<GameRuleException>()));
      expect(() => GameEngine.startNight(good), throwsA(isA<GameRuleException>()));

      final evil = _fiveRejections(_newGame());
      expect(evil.phase, Phase.evilVictory);
      expect(() => GameEngine.pause(evil), throwsA(isA<GameRuleException>()));
      expect(() => GameEngine.beginTeamSelection(evil),
          throwsA(isA<GameRuleException>()));
    });
  });
}
