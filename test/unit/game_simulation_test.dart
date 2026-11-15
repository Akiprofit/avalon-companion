import 'dart:math';

import 'package:avalon_companion/game_engine/engine/game_engine.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/models/game_state.dart';
import 'package:avalon_companion/game_engine/models/phase.dart';
import 'package:avalon_companion/game_engine/models/player.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 11 gate: full matches, played end to end by a seeded random table.
///
/// Every rule the plan states is checked against the state after each step, so a
/// broken transition fails here even when no hand-written case covers it: the
/// table always votes with every hand, the team always matches the quest size,
/// the rejection counter ends the match at five, the two-fail rule is honoured
/// on quest 4, exactly one victory path fires, and a drawn King never serves two
/// rounds in a row.
void main() {
  const playerCounts = [5, 6, 7, 8, 9, 10];
  const names = [
    'Ann',
    'Ben',
    'Cara',
    'Dev',
    'Eli',
    'Fay',
    'Gus',
    'Hana',
    'Ivo',
    'Jun',
  ];

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

  GameState newMatch(int playerCount, {required DateTime startedAt}) =>
      GameEngine.create(
        players: [
          for (var seat = 1; seat <= playerCount; seat++)
            Player(seat: seat, name: names[seat - 1]),
        ],
        composition: compositionFor(playerCount),
        startedAt: startedAt,
      );

  /// Plays one match with a random table and checks every invariant on the way.
  GameState playMatch(
    Random random, {
    required int playerCount,
    required bool drawLord,
    bool skipVote = false,
    DateTime? startedAt,
  }) {
    var state = newMatch(
      playerCount,
      startedAt: startedAt ?? DateTime(2026, 1, 1),
    );
    final roster = state.players.map((p) => p.name).toList();

    var leaders = <int>[];
    var questsPlayed = 0;
    var rejectionsInARow = 0;
    var steps = 0;

    while (!state.phase.isVictory) {
      // A runaway loop is a bug, not a slow test.
      steps++;
      expect(
        steps,
        lessThan(400),
        reason: 'the simulation stopped making progress in ${state.phase}',
      );

      final phase = state.phase;

      if (phase == Phase.preparation) {
        state = GameEngine.startNight(state);
        continue;
      }

      if (phase == Phase.night) {
        state = GameEngine.endNight(state);
        expect(state.phase, Phase.lordSelection);
        continue;
      }

      if (phase == Phase.lordSelection) {
        final seats = GameEngine.drawableLordSeats(state);
        expect(seats, isNotEmpty, reason: 'there is always a King to draw');
        expect(
          seats.toSet().length,
          seats.length,
          reason: 'a draw never repeats a seat',
        );

        // A later draw never offers the King who has just served.
        if (leaders.isNotEmpty) {
          expect(
            seats,
            isNot(contains(leaders.last)),
            reason: 'the serving King stands this draw down',
          );
        }

        final seat = seats[random.nextInt(seats.length)];
        state = GameEngine.chooseLord(state, seat: seat);
        expect(state.phase, Phase.dayDiscussion);
        expect(state.leaderSeat, seat);
        expect(
          state.playerAtSeat(seat),
          isNotNull,
          reason: 'the King is always a seated player',
        );
        continue;
      }

      if (phase == Phase.dayDiscussion) {
        leaders = [...leaders, state.leaderSeat];
        state = GameEngine.beginTeamSelection(state);
        expect(state.phase, Phase.teamSelection);
        continue;
      }

      if (phase == Phase.teamSelection) {
        final size = state.requiredTeamSize;
        expect(
          size,
          AvalonTables.teamSize(playerCount, state.questNumber),
          reason: 'team sizes come from the table only',
        );

        final seats = [for (final player in state.players) player.seat]
          ..shuffle(random);
        final team = seats.take(size).toList();
        state = GameEngine.proposeTeam(state, team, skipVote: skipVote);
        expect(
          state.phase,
          skipVote ? Phase.questResolution : Phase.teamVoting,
        );
        expect(state.currentTeam, team);
        expect(
          state.currentTeam.toSet().length,
          size,
          reason: 'nobody is on the team twice',
        );
        continue;
      }

      if (phase == Phase.teamVoting) {
        final approve = random.nextInt(playerCount + 1);
        final reject = playerCount - approve;
        state = GameEngine.recordVotes(
          state,
          approve: approve,
          reject: reject,
        );
        expect(state.votesComplete, isTrue);

        final expectedApproval = AvalonTables.isApproved(approve, reject);
        final rejectedBefore = state.rejectionCount;
        final kingBefore = state.leaderSeat;
        state = GameEngine.resolveTeamVote(state, drawLord: drawLord);

        if (expectedApproval) {
          expect(state.phase, Phase.questResolution);
          expect(state.rejectionCount, 0);
          rejectionsInARow = 0;
        } else {
          rejectionsInARow++;
          expect(state.rejectionCount, rejectionsInARow);

          if (rejectedBefore + 1 >= 5) {
            expect(
              state.phase,
              Phase.evilVictory,
              reason: 'the fifth rejection ends the match',
            );
            // The final tally is kept for the record.
            expect(state.approveVotes + state.rejectVotes, playerCount);
          } else {
            expect(state.approveVotes, 0);
            expect(state.rejectVotes, 0);
            expect(state.currentTeam, isEmpty);
            expect(
              state.phase,
              drawLord ? Phase.lordSelection : Phase.dayDiscussion,
            );
            if (drawLord) {
              expect(
                state.leaderSeat,
                kingBefore,
                reason: 'the serving King stays until the wheel lands',
              );
            } else {
              expect(
                state.leaderSeat,
                isNot(kingBefore),
                reason: 'the token moves on when the order decides',
              );
            }
          }
        }
        continue;
      }

      if (phase == Phase.questResolution) {
        final teamSize = state.currentTeam.length;
        expect(teamSize, state.requiredTeamSize);
        expect(
          state.currentTeam.toSet().length,
          teamSize,
          reason: 'a quest team never has a duplicate seat',
        );

        final failsRequired = state.failsRequired;
        expect(
          failsRequired,
          AvalonTables.failsRequired(playerCount, state.questNumber),
        );

        final failCards = random.nextInt(teamSize + 1);
        final questNumber = state.questNumber;
        final resultsBefore = state.questResults.length;
        state = GameEngine.recordQuest(
          state,
          failCards: failCards,
          drawLord: drawLord,
          voteSkipped: skipVote,
        );

        questsPlayed++;
        expect(state.questResults, hasLength(resultsBefore + 1));
        expect(
          state.questResults.last,
          failCards >= failsRequired ? QuestResult.fail : QuestResult.success,
          reason: 'the two-fail rule decides quest $questNumber',
        );
        expect(state.questSuccesses + state.questFailures, questsPlayed);
        expect(
          state.questSuccesses <= 3 && state.questFailures <= 3,
          isTrue,
          reason: 'a match never plays a fourth quest of one colour',
        );
        expect(state.currentTeam, isEmpty);
        expect(state.rejectionCount, 0);
        if (skipVote) {
          expect(
            state.hasVotes,
            isFalse,
            reason: 'a team that never faced a vote carries no tally',
          );
        }

        if (state.questSuccesses >= 3) {
          expect(state.phase, Phase.assassination);
        } else if (state.questFailures >= 3) {
          expect(state.phase, Phase.evilVictory);
        } else {
          expect(
            state.phase,
            drawLord ? Phase.lordSelection : Phase.dayDiscussion,
          );
          if (state.phase == Phase.dayDiscussion) {
            expect(
              state.questNumber,
              questNumber + 1,
              reason: 'a resolved quest moves the round on',
            );
          }
        }
        continue;
      }

      if (phase == Phase.assassination) {
        final merlinIdentified = random.nextBool();
        state = GameEngine.resolveAssassination(
          state,
          merlinIdentified: merlinIdentified,
        );
        expect(
          state.phase,
          merlinIdentified ? Phase.evilVictory : Phase.goodVictory,
        );
        expect(state.merlinIdentified, merlinIdentified);
        continue;
      }

      fail('the simulation should never sit in $phase');
    }

    // Ending invariants.
    expect(state.isFinished, isTrue);
    expect([Phase.goodVictory, Phase.evilVictory], contains(state.phase));
    if (state.phase == Phase.goodVictory) {
      expect(state.questSuccesses, 3);
      expect(state.merlinIdentified, isFalse);
    } else {
      final evilByQuests = state.questFailures == 3;
      final evilByMerlin = state.merlinIdentified == true;
      final evilByRejections = state.rejectionCount >= 5;
      expect(
        evilByQuests || evilByMerlin || evilByRejections,
        isTrue,
        reason: 'Evil wins by three quests, by naming Merlin, or by five '
            'rejections',
      );
      expect(
        [evilByQuests, evilByMerlin, evilByRejections]
            .where((reached) => reached)
            .length,
        1,
        reason: 'exactly one victory path fires',
      );
      if (skipVote) {
        expect(
          evilByRejections,
          isFalse,
          reason: 'without a vote there is nothing to reject',
        );
      }
    }

    // The roster is public information only, and it never changes shape.
    expect(state.players, hasLength(playerCount));
    expect(
      state.players.map((p) => p.seat).toList(),
      [for (var seat = 1; seat <= playerCount; seat++) seat],
    );
    expect(state.players.map((p) => p.name).toList(), roster);
    expect(state.composition.playerCount, playerCount);
    expect(
      state.composition.goodTotal + state.composition.evilTotal,
      playerCount,
    );

    return state;
  }

  for (final playerCount in playerCounts) {
    for (final drawLord in [true, false]) {
      for (final skipVote in [false, true]) {
        final mode = '${drawLord ? 'automatic' : 'manual'} King, '
            '${skipVote ? 'no approval vote' : 'approval vote'}';

        test('$playerCount players, $mode: 40 seeded matches hold every rule',
            () {
          for (var seed = 0; seed < 40; seed++) {
            playMatch(
              Random(seed),
              playerCount: playerCount,
              drawLord: drawLord,
              skipVote: skipVote,
            );
          }
        });
      }
    }
  }

  test('Play Again resets the match and keeps the table', () {
    for (final playerCount in playerCounts) {
      final random = Random(playerCount);
      final finished = playMatch(
        random,
        playerCount: playerCount,
        drawLord: true,
      );

      final replay = GameEngine.create(
        players: finished.players,
        composition: compositionFor(playerCount),
        startedAt: DateTime(2026, 2, 1),
      );

      expect(replay.phase, Phase.preparation);
      expect(replay.players, finished.players, reason: 'the roster is kept');
      expect(replay.questResults, isEmpty);
      expect(replay.rejectionCount, 0);
      expect(replay.questNumber, 1);
      expect(replay.currentTeam, isEmpty);
      expect(replay.isFinished, isFalse);
      expect(
        GameEngine.drawableLordSeats(
          GameEngine.endNight(GameEngine.startNight(replay)),
        ),
        [for (var seat = 1; seat <= playerCount; seat++) seat],
        reason: 'a new match draws from the whole table again',
      );
    }
  });

  test('the same seed replays the same match', () {
    final first = playMatch(Random(7), playerCount: 7, drawLord: true);
    final second = playMatch(Random(7), playerCount: 7, drawLord: true);

    expect(second.phase, first.phase);
    expect(second.leaderSeat, first.leaderSeat);
    expect(second.questResults, first.questResults);
    expect(second.questNumber, first.questNumber);
    expect(second.merlinIdentified, first.merlinIdentified);
  });

  test('every victory path is reachable, and only one fires', () {
    final paths = <String, int>{};
    for (var seed = 0; seed < 300; seed++) {
      final state = playMatch(Random(seed), playerCount: 5, drawLord: false);

      // The plan allows exactly three endings: three quests for Good, three
      // quests for Evil, or a correct accusation after Good's third quest.
      final String key;
      if (state.phase == Phase.goodVictory) {
        key = 'good:quests';
      } else if (state.merlinIdentified == true) {
        key = 'evil:merlin';
      } else if (state.questFailures == 3) {
        key = 'evil:quests';
      } else {
        key = 'evil:rejections';
      }
      paths.update(key, (count) => count + 1, ifAbsent: () => 1);

      // A match stops at the first victory; nothing is resolved afterwards.
      expect(state.isFinished, isTrue);
      expect([Phase.goodVictory, Phase.evilVictory], contains(state.phase));
    }

    expect(
      paths.keys,
      containsAll(['good:quests', 'evil:quests', 'evil:merlin']),
    );
    expect(
      paths.values.fold<int>(0, (sum, count) => sum + count),
      300,
      reason: 'every simulated match reached exactly one ending',
    );
  });

  test('five rejections in a row end the match for Evil', () {
    var state = newMatch(5, startedAt: DateTime(2026, 3, 1));
    state = GameEngine.startNight(state);
    state = GameEngine.endNight(state);
    state = GameEngine.chooseLord(state, seat: 1);
    state = GameEngine.beginTeamSelection(state);
    state = GameEngine.proposeTeam(state, [2, 3]);

    for (var rejection = 1; rejection <= 5; rejection++) {
      state = GameEngine.recordVotes(state, approve: 1, reject: 4);
      state = GameEngine.resolveTeamVote(state);
      expect(state.rejectionCount, rejection);

      if (rejection < 5) {
        expect(state.phase, Phase.dayDiscussion);
        state = GameEngine.beginTeamSelection(state);
        state = GameEngine.proposeTeam(state, [2, 3]);
      }
    }

    expect(state.phase, Phase.evilVictory);
    expect(state.questResults, isEmpty, reason: 'no quest was ever approved');
  });

  test('a drawn King never serves two rounds in a row', () {
    var state = newMatch(10, startedAt: DateTime(2026, 4, 1));
    state = GameEngine.startNight(state);
    state = GameEngine.endNight(state);

    final leaders = <int>[];
    final random = Random(99);

    // Every proposal is rejected, so the wheel keeps coming back.
    while (state.phase == Phase.lordSelection) {
      final seats = GameEngine.drawableLordSeats(state);
      if (leaders.isNotEmpty) {
        expect(seats, isNot(contains(leaders.last)));
      }
      final seat = seats[random.nextInt(seats.length)];
      state = GameEngine.chooseLord(state, seat: seat);
      leaders.add(seat);

      state = GameEngine.beginTeamSelection(state);
      final team = [
        for (final player in state.players)
          if (player.seat != state.leaderSeat) player.seat,
      ].take(state.requiredTeamSize).toList();
      state = GameEngine.proposeTeam(state, team);
      state = GameEngine.recordVotes(state, approve: 5, reject: 5);
      state = GameEngine.resolveTeamVote(state, drawLord: true);

      if (state.phase == Phase.questResolution) {
        state = GameEngine.recordQuest(
          state,
          failCards: state.failsRequired,
          drawLord: true,
        );
      }
    }

    expect(leaders.length, greaterThan(1));
    for (var i = 1; i < leaders.length; i++) {
      expect(leaders[i], isNot(leaders[i - 1]));
    }
  });
}
