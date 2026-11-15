import '../rules/avalon_tables.dart';
import 'composition.dart';
import 'phase.dart';
import 'player.dart';
import 'quest_slot.dart';

/// Outcome of a resolved quest.
enum QuestResult { success, fail }

/// Verdict of a team vote.
enum TeamVerdict { approved, rejected }

/// The complete, immutable state of one match.
///
/// Nothing in here associates a character with a player: [composition] is a
/// count per character, and [players] carry a seat and a name only. That is the
/// whole privacy model of the app (master plan §2.2, §8).
///
/// Mutations only happen through `GameEngine`, which rejects invalid
/// transitions; this class is a value object.
class GameState {
  const GameState({
    required this.players,
    required this.composition,
    required this.phase,
    required this.leaderSeat,
    required this.questNumber,
    required this.rejectionCount,
    required this.questResults,
    required this.currentTeam,
    required this.startedAt,
    this.approveVotes = 0,
    this.rejectVotes = 0,
    this.pausedFrom,
    this.merlinIdentified,
    this.finishedAt,
  });

  final List<Player> players;

  /// Characters in play, by count. Never mapped to a player.
  final Composition composition;
  final Phase phase;

  /// Seat holding the leadership token.
  final int leaderSeat;

  /// 1-based index of the quest in progress.
  final int questNumber;
  final int rejectionCount;

  /// Completed quests, in the order they were resolved.
  final List<QuestResult> questResults;

  /// Seats proposed for the current quest. Empty outside a proposal.
  final List<int> currentTeam;

  final int approveVotes;
  final int rejectVotes;

  /// Phase to return to when paused.
  final Phase? pausedFrom;

  /// Result of the accusation. `null` until the assassination is resolved.
  /// Records only whether Merlin was identified — never a target.
  final bool? merlinIdentified;

  final DateTime startedAt;
  final DateTime? finishedAt;

  int get playerCount => players.length;

  bool get isFinished => finishedAt != null;

  bool get hasVotes => approveVotes + rejectVotes > 0;

  bool get votesComplete => approveVotes + rejectVotes == playerCount;

  int get questSuccesses =>
      questResults.where((r) => r == QuestResult.success).length;

  int get questFailures =>
      questResults.where((r) => r == QuestResult.fail).length;

  /// Team size the current quest requires.
  int get requiredTeamSize =>
      AvalonTables.teamSize(playerCount, questNumber);

  /// Fail cards needed to fail the current quest — 2 on quest 4 with 7+ players.
  int get failsRequired => AvalonTables.failsRequired(playerCount, questNumber);

  Player get leader => players.firstWhere(
    (p) => p.seat == leaderSeat,
    orElse: () => players.first,
  );

  /// Public character summary, e.g. "Merlin · Percival · Loyal Servant x2".
  String get compositionSummary => composition.counts.entries
      .map((e) => e.value > 1 ? '${e.key.shortLabel} x${e.value}' : e.key.shortLabel)
      .join(' · ');

  Player? playerAtSeat(int seat) {
    for (final player in players) {
      if (player.seat == seat) return player;
    }
    return null;
  }

  /// Visual state of the five quest slots, derived from [questResults].
  List<QuestSlot> get questSlots {
    return List<QuestSlot>.generate(AvalonTables.questCount, (index) {
      if (index < questResults.length) {
        return questResults[index] == QuestResult.success
            ? QuestSlot.success
            : QuestSlot.fail;
      }
      if (index == questResults.length && phase.isActive) {
        return QuestSlot.current;
      }
      return QuestSlot.pending;
    });
  }

  GameState copyWith({
    List<Player>? players,
    Composition? composition,
    Phase? phase,
    int? leaderSeat,
    int? questNumber,
    int? rejectionCount,
    List<QuestResult>? questResults,
    List<int>? currentTeam,
    int? approveVotes,
    int? rejectVotes,
    Phase? pausedFrom,
    bool? merlinIdentified,
    DateTime? finishedAt,
    bool clearPausedFrom = false,
  }) {
    return GameState(
      players: players ?? this.players,
      composition: composition ?? this.composition,
      phase: phase ?? this.phase,
      leaderSeat: leaderSeat ?? this.leaderSeat,
      questNumber: questNumber ?? this.questNumber,
      rejectionCount: rejectionCount ?? this.rejectionCount,
      questResults: questResults ?? this.questResults,
      currentTeam: currentTeam ?? this.currentTeam,
      approveVotes: approveVotes ?? this.approveVotes,
      rejectVotes: rejectVotes ?? this.rejectVotes,
      pausedFrom: clearPausedFrom ? null : (pausedFrom ?? this.pausedFrom),
      merlinIdentified: merlinIdentified ?? this.merlinIdentified,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}
