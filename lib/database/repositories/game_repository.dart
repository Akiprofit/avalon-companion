import 'dart:convert';

import 'package:drift/drift.dart';

import '../../game_engine/models/character.dart';
import '../../game_engine/models/composition.dart';
import '../../game_engine/models/game_state.dart';
import '../../game_engine/models/phase.dart';
import '../../game_engine/models/player.dart';
import '../../game_engine/rules/avalon_tables.dart';
import '../app_database.dart';
import '../match_store.dart';

export '../match_store.dart';

/// Reads and writes matches â€” the only place that knows the tables.
///
/// Every method takes or returns game-engine models, never Drift rows, and a
/// finished match is written in one transaction with its events.
class GameRepository implements MatchStore {
  GameRepository(this._db);

  final AppDatabase _db;

  /// Writes the first snapshot of a match: the row, its seats and its event.
  @override
  Future<int> createMatch(GameState state) {
    return _db.transaction(() async {
      final id = await _db.into(_db.games).insert(_gamesCompanion(state));
      await _replacePlayers(id, state);
      await _insertEvent(
        id,
        'matchStarted',
        'Match started with ${state.playerCount} players. '
        'Composition: ${state.compositionSummary}.',
      );
      return id;
    });
  }

  /// Updates the snapshot after a confirmed action.
  @override
  Future<void> saveState(int gameId, GameState state) {
    return _db.transaction(() async {
      await (_db.update(_db.games)..where((g) => g.id.equals(gameId))).write(
        _gamesCompanion(state),
      );
      await _replacePlayers(gameId, state);
    });
  }

  /// Appends a resolved team vote (master plan PART 8, `TeamProposals`).
  @override
  Future<void> recordProposal({
    required int gameId,
    required int questNumber,
    required int leaderSeat,
    required List<int> seats,
    required int approve,
    required int reject,
    required TeamVerdict verdict,
  }) {
    final sorted = [...seats]..sort();
    return _db.transaction(() async {
      await _db
          .into(_db.teamProposals)
          .insert(
            TeamProposalsCompanion.insert(
              gameId: gameId,
              questNumber: questNumber,
              leaderSeat: leaderSeat,
              selectedSeats: sorted.join(','),
              approveCount: approve,
              rejectCount: reject,
              result: verdict == TeamVerdict.approved ? 'approved' : 'rejected',
            ),
          );
      await _insertEvent(
        gameId,
        verdict == TeamVerdict.approved ? 'teamApproved' : 'teamRejected',
        'Quest $questNumber: seat ${sorted.join(', ')} '
        '($approve approve, $reject reject). '
        '${verdict == TeamVerdict.approved ? 'Approved' : 'Rejected'}.',
      );
    });
  }

  /// Appends a resolved quest (master plan PART 8, `Quests`).
  @override
  Future<void> recordQuest({
    required int gameId,
    required int questNumber,
    required int requiredPlayers,
    required int failCards,
    required QuestResult result,
  }) {
    final successes = requiredPlayers - failCards;
    return _db.transaction(() async {
      await _db
          .into(_db.quests)
          .insert(
            QuestsCompanion.insert(
              gameId: gameId,
              questNumber: questNumber,
              requiredPlayers: requiredPlayers,
              successCount: successes < 0 ? 0 : successes,
              failCount: failCards,
              result: result == QuestResult.success ? 'success' : 'fail',
            ),
          );
      await _insertEvent(
        gameId,
        result == QuestResult.success ? 'questSucceeded' : 'questFailed',
        'Quest $questNumber ${result == QuestResult.success ? 'succeeded' : 'failed'}: '
        '$failCards fail ${failCards == 1 ? 'card' : 'cards'} out of '
        '$requiredPlayers.',
      );
    });
  }

  /// Public log lines, newest last.
  @override
  Future<void> addEvent(int gameId, String type, String description) =>
      _insertEvent(gameId, type, description);

  /// The match to offer as **Continue Game**, if one is still running.
  @override
  Future<StoredMatch?> findInProgress() async {
    final row =
        await (_db.select(_db.games)
              ..where((g) => g.status.equals(MatchStatus.inProgress))
              ..orderBy([(g) => OrderingTerm.desc(g.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    return StoredMatch(id: row.id, state: await _stateOf(row));
  }

  /// History list, newest first, paged.
  @override
  Future<List<MatchSummary>> matches({int limit = 50, int offset = 0}) async {
    final rows =
        await (_db.select(_db.games)
              ..orderBy([(g) => OrderingTerm.desc(g.updatedAt)])
              ..limit(limit, offset: offset))
            .get();
    return rows.map(_summaryOf).toList();
  }

  Future<List<EventRecord>> events(int gameId) {
    return (_db.select(_db.gameEvents)
          ..where((e) => e.gameId.equals(gameId))
          ..orderBy([(e) => OrderingTerm.asc(e.id)]))
        .get();
  }

  Future<List<ProposalRecord>> proposals(int gameId) {
    return (_db.select(_db.teamProposals)
          ..where((p) => p.gameId.equals(gameId))
          ..orderBy([(p) => OrderingTerm.asc(p.id)]))
        .get();
  }

  Future<List<QuestRecord>> quests(int gameId) {
    return (_db.select(_db.quests)
          ..where((q) => q.gameId.equals(gameId))
          ..orderBy([(q) => OrderingTerm.asc(q.id)]))
        .get();
  }

  /// Removes a match and, by cascade, every row that belongs to it.
  Future<void> deleteMatch(int gameId) async {
    await (_db.delete(_db.games)..where((g) => g.id.equals(gameId))).go();
  }

  @override
  Future<void> markAbandoned(int gameId) async {
    await (_db.update(_db.games)..where((g) => g.id.equals(gameId))).write(
      GamesCompanion(
        status: const Value(MatchStatus.abandoned),
        updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> _insertEvent(int gameId, String type, String description) async {
    await _db
        .into(_db.gameEvents)
        .insert(
          GameEventsCompanion.insert(
            gameId: gameId,
            eventType: type,
            eventDescription: description,
            createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> _replacePlayers(int gameId, GameState state) async {
    await (_db.delete(_db.players)..where((p) => p.gameId.equals(gameId))).go();
    await _db.batch((batch) {
      batch.insertAll(_db.players, [
        for (final player in state.players)
          PlayersCompanion.insert(
            gameId: gameId,
            displayName: player.name,
            seatNumber: player.seat,
          ),
      ]);
    });
  }

  GamesCompanion _gamesCompanion(GameState state) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final finished = state.isFinished;
    return GamesCompanion(
      createdAt: Value(state.startedAt.toUtc().millisecondsSinceEpoch),
      updatedAt: Value(now),
      playerCount: Value(state.playerCount),
      status: Value(
        finished ? MatchStatus.finished : MatchStatus.inProgress,
      ),
      winner: Value(finished ? _winnerOf(state) : null),
      durationSeconds: Value(
        finished ? state.finishedAt!.difference(state.startedAt).inSeconds : null,
      ),
      phase: Value(state.phase.name),
      pausedFrom: Value(state.pausedFrom?.name),
      leaderSeat: Value(state.leaderSeat),
      questNumber: Value(state.questNumber),
      rejectionCount: Value(state.rejectionCount),
      questResults: Value(
        state.questResults.map((r) => r.name).join(','),
      ),
      currentTeam: Value(
        ([...state.currentTeam]..sort()).join(','),
      ),
      composition: Value(_encodeComposition(state.composition)),
      winReason: Value(finished ? winReasonOf(state) : null),
      assassinationOutcome: Value(
        state.merlinIdentified == null
            ? null
            : (state.merlinIdentified! ? 'identified' : 'notIdentified'),
      ),
    );
  }

  Future<GameState> _stateOf(GameRecord row) async {
    final seats =
        await (_db.select(_db.players)
              ..where((p) => p.gameId.equals(row.id))
              ..orderBy([(p) => OrderingTerm.asc(p.seatNumber)]))
            .get();
    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      row.createdAt,
      isUtc: true,
    ).toLocal();
    final finished = row.status == MatchStatus.finished;
    return GameState(
      players: List<Player>.unmodifiable([
        for (final seat in seats)
          Player(seat: seat.seatNumber, name: seat.displayName),
      ]),
      composition: _decodeComposition(row.composition, row.playerCount),
      phase: _decodePhase(row.phase, row.pausedFrom),
      leaderSeat: row.leaderSeat,
      questNumber: row.questNumber,
      rejectionCount: row.rejectionCount,
      questResults: List<QuestResult>.unmodifiable([
        for (final code in row.questResults.split(','))
          if (code.isNotEmpty)
            code == QuestResult.success.name
                ? QuestResult.success
                : QuestResult.fail,
      ]),
      currentTeam: List<int>.unmodifiable([
        for (final seat in row.currentTeam.split(','))
          if (seat.isNotEmpty) int.tryParse(seat) ?? 0,
      ].where((seat) => seat > 0)),
      approveVotes: 0,
      rejectVotes: 0,
      pausedFrom: row.pausedFrom == null
          ? null
          : _decodePhase(row.pausedFrom!, null),
      merlinIdentified: switch (row.assassinationOutcome) {
        'identified' => true,
        'notIdentified' => false,
        _ => null,
      },
      startedAt: startedAt,
      finishedAt: finished && row.durationSeconds != null
          ? startedAt.add(Duration(seconds: row.durationSeconds!))
          : null,
    );
  }

  MatchSummary _summaryOf(GameRecord row) {
    return MatchSummary(
      id: row.id,
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ).toLocal(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ).toLocal(),
      playerCount: row.playerCount,
      status: row.status,
      questResults: [
        for (final code in row.questResults.split(','))
          if (code.isNotEmpty)
            code == QuestResult.success.name
                ? QuestResult.success
                : QuestResult.fail,
      ],
      winner: row.winner,
      winReason: row.winReason,
      durationSeconds: row.durationSeconds,
      assassinationOutcome: row.assassinationOutcome,
    );
  }

  static String? _winnerOf(GameState state) => switch (state.phase) {
    Phase.goodVictory => 'good',
    Phase.evilVictory => 'evil',
    _ => null,
  };

  static String? winReasonOf(GameState state) {
    if (!state.isFinished) return null;
    if (state.phase == Phase.goodVictory) return WinReason.threeQuests;
    if (state.merlinIdentified == true) return WinReason.assassination;
    if (state.rejectionCount >= 5) return WinReason.fiveRejections;
    return WinReason.threeQuests;
  }

  static String _encodeComposition(Composition composition) {
    return jsonEncode({
      for (final entry in composition.counts.entries) entry.key.name: entry.value,
    });
  }

  static Composition _decodeComposition(String encoded, int playerCount) {
    final counts = <Character, int>{};
    final decoded = jsonDecode(encoded);
    if (decoded is Map) {
      for (final entry in decoded.entries) {
        final character = Character.values
            .where((c) => c.name == entry.key)
            .firstOrNull;
        final count = entry.value;
        if (character != null && count is int && count > 0) {
          counts[character] = count;
        }
      }
    }
    return Composition(playerCount: playerCount, counts: counts);
  }

  static Phase _decodePhase(String code, String? pausedFrom) {
    for (final phase in Phase.values) {
      if (phase.name == code) return phase;
    }
    // An unknown code means a newer save; fall back to the safest phase rather
    // than losing the match.
    return pausedFrom == null ? Phase.dayDiscussion : Phase.paused;
  }
}

/// Team size for a quest, used when writing a quest row.
int requiredPlayersFor(int playerCount, int questNumber) =>
    AvalonTables.teamSize(playerCount, questNumber);
