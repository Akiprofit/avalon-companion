import '../game_engine/models/game_state.dart';

/// Status codes stored in `Games.status`.
abstract final class MatchStatus {
  static const inProgress = 'inProgress';
  static const finished = 'finished';
  static const abandoned = 'abandoned';
}

/// Reasons stored in `Games.winReason`.
abstract final class WinReason {
  static const threeQuests = 'threeQuests';
  static const fiveRejections = 'fiveRejections';
  static const assassination = 'assassination';
}

/// One row of the history list, decoded from the database.
///
/// Only public information: how the match ended, how many players sat down and
/// which quests passed. There is no character column to leak (master plan §2.2).
class MatchSummary {
  const MatchSummary({
    required this.id,
    required this.startedAt,
    required this.updatedAt,
    required this.playerCount,
    required this.status,
    required this.questResults,
    this.winner,
    this.winReason,
    this.durationSeconds,
    this.assassinationOutcome,
  });

  final int id;
  final DateTime startedAt;
  final DateTime updatedAt;
  final int playerCount;
  final String status;
  final List<QuestResult> questResults;
  final String? winner;
  final String? winReason;
  final int? durationSeconds;
  final String? assassinationOutcome;

  bool get isFinished => status == MatchStatus.finished;
  bool get isAbandoned => status == MatchStatus.abandoned;
  bool get isInProgress => status == MatchStatus.inProgress;

  int get successCount =>
      questResults.where((r) => r == QuestResult.success).length;
  int get failCount => questResults.where((r) => r == QuestResult.fail).length;

  Duration? get duration =>
      durationSeconds == null ? null : Duration(seconds: durationSeconds!);
}

/// A match loaded for recovery, with the row id that later saves update.
class StoredMatch {
  const StoredMatch({required this.id, required this.state});

  final int id;
  final GameState state;
}

/// Everything the running match needs from storage.
///
/// The controller talks to this interface, never to Drift, which keeps the live
/// match testable with a fake and lets the app run with no database at all (a
/// failure to open the file must never stop a game at the table).
abstract interface class MatchStore {
  /// Writes the first snapshot of a match and returns its row id.
  Future<int> createMatch(GameState state);

  /// Updates the snapshot after a confirmed action.
  Future<void> saveState(int gameId, GameState state);

  /// Appends a resolved team vote.
  Future<void> recordProposal({
    required int gameId,
    required int questNumber,
    required int leaderSeat,
    required List<int> seats,
    required int approve,
    required int reject,
    required TeamVerdict verdict,
  });

  /// Appends a resolved quest.
  Future<void> recordQuest({
    required int gameId,
    required int questNumber,
    required int requiredPlayers,
    required int failCards,
    required QuestResult result,
  });

  /// Appends one line of the public log.
  Future<void> addEvent(int gameId, String type, String description);

  /// Marks an interrupted match as abandoned, keeping it in the history.
  Future<void> markAbandoned(int gameId);

  /// The match to offer as **Continue Game**, if one is still running.
  Future<StoredMatch?> findInProgress();

  /// History list, newest first.
  Future<List<MatchSummary>> matches({int limit, int offset});
}
