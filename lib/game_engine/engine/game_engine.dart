import '../models/composition.dart';
import '../models/game_state.dart';
import '../models/phase.dart';
import '../models/player.dart';
import '../rules/avalon_tables.dart';

/// Raised when a command is not legal in the current state.
///
/// The message is written for the MC: a plain sentence, no codes.
class GameRuleException implements Exception {
  const GameRuleException(this.message);

  final String message;

  @override
  String toString() => 'GameRuleException: $message';
}

/// The Avalon base-game state machine (master plan §5).
///
/// Every function is pure: it takes a [GameState] and returns a new one, or
/// throws [GameRuleException] if the command is illegal. No Flutter import is
/// allowed in this file — the rules must stay independently testable.
abstract final class GameEngine {
  /// Creates a match in [Phase.preparation].
  ///
  /// The character composition is validated here as a hard gate: a match cannot
  /// begin with the wrong good/evil split or a duplicated unique character.
  static GameState create({
    required List<Player> players,
    required Composition composition,
    DateTime? startedAt,
  }) {
    if (!AvalonTables.isValidPlayerCount(players.length)) {
      throw const GameRuleException(
        'Avalon is played with 5 to 10 players.',
      );
    }
    if (composition.playerCount != players.length) {
      throw GameRuleException(
        'The composition is built for ${composition.playerCount} players, '
        'but ${players.length} seats are filled.',
      );
    }
    if (!composition.isValid) {
      final first = composition.errors.first.message;
      throw GameRuleException(first);
    }

    final seats = players.map((p) => p.seat).toSet();
    if (seats.length != players.length) {
      throw const GameRuleException('Two players share the same seat.');
    }

    return GameState(
      players: List<Player>.unmodifiable(
        players.toList()..sort((a, b) => a.seat.compareTo(b.seat)),
      ),
      composition: composition,
      phase: Phase.preparation,
      leaderSeat: players.first.seat,
      questNumber: 1,
      rejectionCount: 0,
      questResults: const [],
      currentTeam: const [],
      startedAt: startedAt ?? DateTime.now(),
    );
  }

  /// Preparation -> Night.
  static GameState startNight(GameState state) {
    _require(state.phase == Phase.preparation, state,
        'The night can only begin from the preparation phase.');
    return state.copyWith(phase: Phase.night);
  }

  /// Night -> LordSelection. The first Lord is drawn at random, so the round
  /// table starts with a fresh draw rather than always seat 1.
  static GameState endNight(GameState state) {
    _require(state.phase == Phase.night, state,
        'There is no night in progress to end.');
    return state.copyWith(phase: Phase.lordSelection);
  }

  /// LordSelection -> DayDiscussion. Sets the seat drawn by the wheel.
  ///
  /// The draw itself is random and lives in the UI; this command is pure so the
  /// transition stays testable and an impossible seat is refused. It is used
  /// once after the night and again at the start of every round when the table
  /// draws a new King (see [beginLordDraw]).
  static GameState chooseLord(GameState state, {required int seat}) {
    _require(state.phase == Phase.lordSelection, state,
        'The Lord is only chosen while the wheel is open.');
    _require(state.playerAtSeat(seat) != null, state,
        'There is no player in seat $seat.');
    return state.copyWith(leaderSeat: seat, phase: Phase.dayDiscussion);
  }

  /// Opens the wheel for the current round.
  ///
  /// Used by the manual King mode: the MC asks for a draw between rounds. The
  /// leadership token is left where it is until the wheel lands, so the draw
  /// knows which King has just served and can avoid repeating them.
  static GameState beginLordDraw(GameState state) {
    _require(state.phase != Phase.lordSelection, state,
        'The wheel is already open.');
    _require(
      state.phase == Phase.dayDiscussion || state.phase == Phase.teamSelection,
      state,
      'A new King is drawn between rounds, not during a vote or a quest.',
    );
    return state.copyWith(phase: Phase.lordSelection);
  }

  /// Seats the wheel may land on for the draw that is open now.
  ///
  /// The opening draw of a match takes the whole table: no King has served yet,
  /// so every seat is equally owed the token. Every later draw leaves out the
  /// King who has just served, so one player does not lead twice in a row while
  /// there is somebody else to lead. A single-seat table still draws that seat.
  static List<int> drawableLordSeats(GameState state) {
    final seats = [for (final player in state.players) player.seat];
    if (seats.length < 2) return seats;
    final firstDrawOfMatch =
        state.questNumber == 1 &&
        state.questResults.isEmpty &&
        state.rejectionCount == 0;
    if (firstDrawOfMatch) return seats;
    return [
      for (final seat in seats)
        if (seat != state.leaderSeat) seat,
    ];
  }

  /// DayDiscussion -> TeamSelection.
  static GameState beginTeamSelection(GameState state) {
    _require(state.phase == Phase.dayDiscussion, state,
        'Team selection follows the discussion.');
    return state.copyWith(phase: Phase.teamSelection);
  }

  /// TeamSelection -> TeamVoting, or straight to QuestResolution with [skipVote].
  ///
  /// [skipVote] is the house rule set in Settings: the leader names the team and
  /// the quest is played without an approval vote. The proposal is validated
  /// exactly the same way, and no vote is recorded, so the rejection counter and
  /// the five-rejection loss never come into play.
  static GameState proposeTeam(
    GameState state,
    List<int> seats, {
    bool skipVote = false,
  }) {
    _require(state.phase == Phase.teamSelection, state,
        'Propose a team during team selection.');
    _require(seats.length == state.requiredTeamSize, state,
        'Quest ${state.questNumber} needs ${state.requiredTeamSize} players on '
        'the team, ${seats.length} were chosen.');
    _require(seats.toSet().length == seats.length, state,
        'A player cannot be on the team twice.');
    for (final seat in seats) {
      _require(state.playerAtSeat(seat) != null, state,
          'There is no player in seat $seat.');
    }

    return state.copyWith(
      phase: skipVote ? Phase.questResolution : Phase.teamVoting,
      currentTeam: List<int>.unmodifiable(seats),
      approveVotes: 0,
      rejectVotes: 0,
    );
  }

  /// TeamVoting, before resolution. Vote totals must account for every player.
  static GameState recordVotes(
    GameState state, {
    required int approve,
    required int reject,
  }) {
    _require(state.phase == Phase.teamVoting, state,
        'Votes are only recorded while the team is being voted on.');
    _require(approve >= 0 && reject >= 0, state,
        'Vote totals cannot be negative.');
    _require(approve + reject == state.playerCount, state,
        '${state.playerCount} players vote; $approve approve and $reject '
        'reject add up to ${approve + reject}.');
    return state.copyWith(approveVotes: approve, rejectVotes: reject);
  }

  /// Resolves the vote, applies the rejection counter and rotates the token.
  ///
  /// The token advances after every resolved proposal, approved or rejected
  /// (master plan §5.5). With [drawLord] the token is left with the King who
  /// has just served and the table returns to the wheel instead: the draw — not
  /// seating order — picks the next King, and it can avoid repeating a player.
  static GameState resolveTeamVote(
    GameState state, {
    bool drawLord = false,
  }) {
    _require(state.phase == Phase.teamVoting, state,
        'There is no team vote to resolve.');
    _require(state.votesComplete, state,
        'Record all ${state.playerCount} votes before resolving.');

    final approved =
        AvalonTables.isApproved(state.approveVotes, state.rejectVotes);
    final nextLeader = _nextLeaderSeat(state);

    if (approved) {
      return state.copyWith(
        phase: Phase.questResolution,
        leaderSeat: drawLord ? state.leaderSeat : nextLeader,
        rejectionCount: 0,
      );
    }

    final rejections = state.rejectionCount + 1;
    if (rejections >= 5) {
      return state.copyWith(
        phase: Phase.evilVictory,
        leaderSeat: nextLeader,
        rejectionCount: rejections,
        finishedAt: DateTime.now(),
      );
    }

    return state.copyWith(
      phase: drawLord ? Phase.lordSelection : Phase.dayDiscussion,
      leaderSeat: drawLord ? state.leaderSeat : nextLeader,
      rejectionCount: rejections,
      currentTeam: const [],
      approveVotes: 0,
      rejectVotes: 0,
    );
  }

  /// QuestResolution: records one resolved quest and moves the match on.
  ///
  /// Three successes send the game to the assassination; three failures end it
  /// for evil. Anything else returns to discussion with the next quest number,
  /// or to the wheel when [drawLord] asks for a new King first.
  static GameState recordQuest(
    GameState state, {
    required int failCards,
    bool drawLord = false,
    bool voteSkipped = false,
  }) {
    _require(state.phase == Phase.questResolution, state,
        'Quests are only resolved after an approved team.');
    _require(state.questResults.length + 1 == state.questNumber, state,
        'Quest ${state.questNumber} was already resolved.');
    _require(state.currentTeam.isNotEmpty, state,
        'No team has been approved for this quest.');
    _require(failCards >= 0 && failCards <= state.currentTeam.length, state,
        'A quest of ${state.currentTeam.length} players cannot produce '
        '$failCards fail cards.');

    final failed = failCards >= state.failsRequired;
    final results = List<QuestResult>.unmodifiable([
      ...state.questResults,
      failed ? QuestResult.fail : QuestResult.success,
    ]);

    final successes = results.where((r) => r == QuestResult.success).length;
    final failures = results.where((r) => r == QuestResult.fail).length;

    if (successes >= 3) {
      return state.copyWith(
        phase: Phase.assassination,
        questResults: results,
        currentTeam: const [],
        approveVotes: 0,
        rejectVotes: 0,
      );
    }
    if (failures >= 3) {
      return state.copyWith(
        phase: Phase.evilVictory,
        questResults: results,
        currentTeam: const [],
        approveVotes: 0,
        rejectVotes: 0,
        finishedAt: DateTime.now(),
      );
    }

    return state.copyWith(
      phase: drawLord ? Phase.lordSelection : Phase.dayDiscussion,
      // The wheel keeps the serving King so the draw can leave them out; with
      // [voteSkipped] the token was never moved by an approval, so the round
      // passes it on here instead.
      leaderSeat: !drawLord && voteSkipped ? _nextLeaderSeat(state) : null,
      questResults: results,
      questNumber: state.questNumber + 1,
      rejectionCount: 0,
      currentTeam: const [],
      approveVotes: 0,
      rejectVotes: 0,
    );
  }

  /// Assassination -> GoodVictory or EvilVictory.
  ///
  /// Only the outcome is recorded. The app never learns, stores or asks who was
  /// named (master plan §2.2).
  static GameState resolveAssassination(
    GameState state, {
    required bool merlinIdentified,
  }) {
    _require(state.phase == Phase.assassination, state,
        'The accusation only happens after three successful quests.');
    return state.copyWith(
      phase: merlinIdentified ? Phase.evilVictory : Phase.goodVictory,
      merlinIdentified: merlinIdentified,
      finishedAt: DateTime.now(),
    );
  }

  /// Pauses any running phase.
  static GameState pause(GameState state) {
    _require(!state.isFinished, state, 'The match is already over.');
    _require(state.phase != Phase.paused, state, 'The match is already paused.');
    _require(
      state.phase.isActive || state.phase == Phase.preparation,
      state,
      'There is nothing running to pause.',
    );
    return state.copyWith(phase: Phase.paused, pausedFrom: state.phase);
  }

  /// Returns to the phase that was interrupted.
  static GameState resume(GameState state) {
    _require(state.phase == Phase.paused, state, 'The match is not paused.');
    final previous = state.pausedFrom ?? Phase.dayDiscussion;
    return state.copyWith(phase: previous, clearPausedFrom: true);
  }

  /// Seat that follows [GameState.leaderSeat] in seating order, wrapping around.
  static int _nextLeaderSeat(GameState state) {
    final seats = state.players.map((p) => p.seat).toList()..sort();
    final index = seats.indexOf(state.leaderSeat);
    if (index < 0) return seats.first;
    return seats[(index + 1) % seats.length];
  }

  static void _require(bool condition, GameState state, String message) {
    if (!condition) throw GameRuleException(message);
  }
}
