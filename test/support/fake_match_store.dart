import 'package:avalon_companion/database/match_store.dart';
import 'package:avalon_companion/game_engine/models/game_state.dart';

/// One resolved team vote, as the fake saw it.
class FakeProposal {
  FakeProposal({
    required this.gameId,
    required this.questNumber,
    required this.leaderSeat,
    required this.seats,
    required this.approve,
    required this.reject,
    required this.verdict,
  });

  final int gameId;
  final int questNumber;
  final int leaderSeat;
  final List<int> seats;
  final int approve;
  final int reject;
  final TeamVerdict verdict;
}

/// One resolved quest, as the fake saw it.
class FakeQuest {
  FakeQuest({
    required this.gameId,
    required this.questNumber,
    required this.requiredPlayers,
    required this.failCards,
    required this.result,
  });

  final int gameId;
  final int questNumber;
  final int requiredPlayers;
  final int failCards;
  final QuestResult result;
}

/// An in-memory [MatchStore] that records every call, so the wiring can be
/// tested without SQLite.
class FakeMatchStore implements MatchStore {
  int _nextId = 1;

  /// Every snapshot written at creation, by row id.
  final Map<int, GameState> created = {};

  /// Every snapshot written after an action, oldest first.
  final List<GameState> saved = [];

  final List<FakeProposal> proposals = [];
  final List<FakeQuest> quests = [];
  final List<String> events = [];

  /// Row ids marked abandoned, in order.
  final List<int> abandoned = [];

  /// What [findInProgress] returns.
  StoredMatch? inProgress;

  /// What [matches] returns.
  List<MatchSummary> summaries = const [];

  /// When set, every write throws, to prove a broken disk cannot stop a match.
  bool broken = false;

  GameState? get latest => saved.isEmpty ? null : saved.last;

  @override
  Future<int> createMatch(GameState state) async {
    _check();
    final id = _nextId++;
    created[id] = state;
    return id;
  }

  @override
  Future<void> saveState(int gameId, GameState state) async {
    _check();
    saved.add(state);
  }

  @override
  Future<void> recordProposal({
    required int gameId,
    required int questNumber,
    required int leaderSeat,
    required List<int> seats,
    required int approve,
    required int reject,
    required TeamVerdict verdict,
  }) async {
    _check();
    proposals.add(
      FakeProposal(
        gameId: gameId,
        questNumber: questNumber,
        leaderSeat: leaderSeat,
        seats: seats,
        approve: approve,
        reject: reject,
        verdict: verdict,
      ),
    );
  }

  @override
  Future<void> recordQuest({
    required int gameId,
    required int questNumber,
    required int requiredPlayers,
    required int failCards,
    required QuestResult result,
  }) async {
    _check();
    quests.add(
      FakeQuest(
        gameId: gameId,
        questNumber: questNumber,
        requiredPlayers: requiredPlayers,
        failCards: failCards,
        result: result,
      ),
    );
  }

  @override
  Future<void> addEvent(int gameId, String type, String description) async {
    _check();
    events.add('$type: $description');
  }

  @override
  Future<void> markAbandoned(int gameId) async {
    _check();
    abandoned.add(gameId);
  }

  @override
  Future<StoredMatch?> findInProgress() async => inProgress;

  @override
  Future<List<MatchSummary>> matches({int limit = 50, int offset = 0}) async =>
      summaries;

  /// Deletes from the same list [matches] hands out, oldest first, so a widget
  /// test can watch the screen update.
  @override
  Future<int> deleteHistory({int? count}) async {
    _check();
    // The real store orders by `updatedAt` ascending: oldest first.
    final deletable = summaries.where((m) => !m.isInProgress).toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    final doomed = count == null ? deletable : deletable.take(count).toList();
    final doomedIds = {for (final match in doomed) match.id};
    summaries = [
      for (final match in summaries)
        if (!doomedIds.contains(match.id)) match,
    ];
    return doomed.length;
  }

  void _check() {
    if (broken) throw StateError('the disk is full');
  }
}

/// A summary that needs no database.
MatchSummary summaryOf({
  int id = 1,
  DateTime? startedAt,
  String status = MatchStatus.finished,
  String? winner = 'good',
  String? winReason = WinReason.threeQuests,
  int playerCount = 5,
  List<QuestResult> questResults = const [
    QuestResult.success,
    QuestResult.success,
    QuestResult.success,
  ],
  String? assassinationOutcome,
  int? durationSeconds = 900,
}) {
  final now = startedAt ?? DateTime(2026, 11, 15, 20, 30);
  return MatchSummary(
    id: id,
    startedAt: now,
    updatedAt: now,
    playerCount: playerCount,
    status: status,
    questResults: questResults,
    winner: winner,
    winReason: winReason,
    durationSeconds: durationSeconds,
    assassinationOutcome: assassinationOutcome,
  );
}
