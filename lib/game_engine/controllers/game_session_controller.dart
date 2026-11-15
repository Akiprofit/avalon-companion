import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../database/match_store.dart';
import '../engine/game_engine.dart';
import '../models/composition.dart';
import '../models/game_state.dart';
import '../models/phase.dart';
import '../models/player.dart';

/// The live match. Every mutation goes through [GameEngine], so an illegal
/// transition is impossible from the UI: it throws instead of corrupting state.
///
/// Persistence is a side effect, never a dependency: the state changes first and
/// synchronously, then the same snapshot is queued for the database. A report of
/// two updates can never interleave, because the writes are chained one after
/// the other, and a failed write is swallowed — a match at the table must not
/// stop because a disk was busy.
class GameSessionController extends Notifier<GameState?> {
  int? _gameId;
  Future<void> _writes = Future<void>.value();

  @override
  GameState? build() {
    final restored = ref.watch(restoredMatchProvider);
    _gameId = restored?.id;
    return restored?.state;
  }

  /// Starts a match. Any match still running is kept in the history as
  /// abandoned, never deleted.
  void start({required List<String> names, required Composition composition}) {
    final players = [
      for (var i = 0; i < names.length; i++)
        Player(seat: i + 1, name: names[i].trim()),
    ];
    final game = GameEngine.create(players: players, composition: composition);
    _beginNewMatch(game);
  }

  /// Preparation -> Night. Ignored if the night already started, so reopening
  /// the narration screen never rewinds or duplicates the phase change.
  void startNight() {
    final game = state;
    if (game == null || game.phase != Phase.preparation) return;
    _apply(GameEngine.startNight(game));
  }

  /// Night -> LordSelection. Ignored once the night is over.
  void endNight() {
    final game = state;
    if (game == null || game.phase != Phase.night) return;
    _apply(GameEngine.endNight(game));
  }

  /// Draws the Lord. The wheel picks the seat; the engine validates it and
  /// moves the table into the day. Used once after the night, and again at the
  /// start of every round in the automatic King mode.
  void chooseLord(int seat) {
    final game = state;
    if (game == null || game.phase != Phase.lordSelection) return;
    final next = GameEngine.chooseLord(game, seat: seat);
    _applyWith(next, (store, id) async {
      await store.saveState(id, next);
      await store.addEvent(
        id,
        'lordDrawn',
        'The wheel drew the Lord for quest ${game.questNumber}: seat $seat.',
      );
    });
  }

  /// Opens the wheel between rounds. Ignored unless the table is between a
  /// vote and the cards, so a draw can never interrupt a running tally.
  void beginLordDraw() {
    final game = state;
    if (game == null) return;
    if (game.phase != Phase.dayDiscussion &&
        game.phase != Phase.teamSelection) {
      return;
    }
    _apply(GameEngine.beginLordDraw(game));
  }

  /// Starts a fresh match with the same table.
  ///
  /// The roster and the composition carry over; every quest, vote, rejection,
  /// the drawn Lord, the accusation and the result are dropped, because a new
  /// [GameState] is built from scratch. Roles are never stored, so nothing
  /// character-related could leak into the new match either way.
  void playAgain() {
    final game = state;
    if (game == null || !game.isFinished) return;
    _beginNewMatch(
      GameEngine.create(
        players: [
          for (final player in game.players)
            Player(seat: player.seat, name: player.name),
        ],
        composition: game.composition,
      ),
    );
  }

  /// DayDiscussion -> TeamSelection. Ignored when the MC is already choosing,
  /// so reopening the screen never rewinds anything.
  void beginTeamSelection() {
    final game = state;
    if (game == null || game.phase != Phase.dayDiscussion) return;
    _apply(GameEngine.beginTeamSelection(game));
  }

  /// Sends the chosen seats to the vote — or, with [skipVote], straight to the
  /// quest when the approval vote is switched off in Settings. The engine
  /// refuses a wrong size either way.
  void proposeTeam(List<int> seats, {bool skipVote = false}) {
    final game = state;
    if (game == null) return;
    _apply(GameEngine.proposeTeam(game, seats, skipVote: skipVote));
  }

  /// Records the physical vote. The MC counts hands; the engine refuses totals
  /// that do not account for the whole table.
  void recordVotes({required int approve, required int reject}) {
    final game = state;
    if (game == null || game.phase != Phase.teamVoting) return;
    _apply(GameEngine.recordVotes(game, approve: approve, reject: reject));
  }

  /// Applies the vote: approval sends the team to the quest, rejection moves
  /// the leader token — or opens the wheel for a new King when [drawLord] is set
  /// — and five rejections end the match for evil.
  void resolveTeamVote({bool drawLord = false}) {
    final game = state;
    if (game == null || game.phase != Phase.teamVoting) return;

    // Capture the proposal before it is consumed by the transition.
    final questNumber = game.questNumber;
    final leaderSeat = game.leaderSeat;
    final seats = [...game.currentTeam];
    final approve = game.approveVotes;
    final reject = game.rejectVotes;
    final next = GameEngine.resolveTeamVote(game, drawLord: drawLord);

    final verdict = next.phase == Phase.questResolution
        ? TeamVerdict.approved
        : TeamVerdict.rejected;
    _applyWith(next, (store, id) async {
      await store.recordProposal(
        gameId: id,
        questNumber: questNumber,
        leaderSeat: leaderSeat,
        seats: seats,
        approve: approve,
        reject: reject,
        verdict: verdict,
      );
      await store.saveState(id, next);
    });
  }

  /// Records the cards played on the approved quest. Only the fail count is
  /// needed: the engine derives the successes from the team size, decides the
  /// quest 4 two-fail rule and moves the match on — to the next round, or to the
  /// wheel when [drawLord] is set.
  ///
  /// [voteSkipped] comes from the approval-vote setting: with no vote there was
  /// no approval to move the leadership token, so this is where it passes on.
  void recordQuest({
    required int failCards,
    bool drawLord = false,
    bool voteSkipped = false,
  }) {
    final game = state;
    if (game == null || game.phase != Phase.questResolution) return;

    final questNumber = game.questNumber;
    final requiredPlayers = game.currentTeam.length;
    final next = GameEngine.recordQuest(
      game,
      failCards: failCards,
      drawLord: drawLord,
      voteSkipped: voteSkipped,
    );

    final result = next.questResults.last;
    _applyWith(next, (store, id) async {
      await store.recordQuest(
        gameId: id,
        questNumber: questNumber,
        requiredPlayers: requiredPlayers,
        failCards: failCards,
        result: result,
      );
      await store.saveState(id, next);
    });
  }

  /// Records the accusation. Only the outcome is stored: whether Merlin was
  /// named. The app never asks for, or keeps, the name (master plan §2.2).
  void resolveAssassination({required bool merlinIdentified}) {
    final game = state;
    if (game == null || game.phase != Phase.assassination) return;
    final next = GameEngine.resolveAssassination(
      game,
      merlinIdentified: merlinIdentified,
    );
    _applyWith(next, (store, id) async {
      await store.saveState(id, next);
      await store.addEvent(
        id,
        'matchEnded',
        next.phase == Phase.goodVictory
            ? 'Good won: Merlin survived the accusation.'
            : 'Evil won: Merlin was identified.',
      );
    });
  }

  void togglePause() {
    final game = state;
    if (game == null) return;
    _apply(
      game.phase == Phase.paused
          ? GameEngine.resume(game)
          : GameEngine.pause(game),
    );
  }

  /// Leaves the match. It stays in the history as abandoned so the table can
  /// see how the evening went; nothing is deleted.
  void abort() {
    final id = _gameId;
    if (id != null) {
      _enqueue((store) => store.markAbandoned(id));
    }
    _gameId = null;
    state = null;
  }

  /// Completes when every queued write has been attempted.
  ///
  /// The UI never waits; tests use it to inspect what reached storage, and a
  /// future shutdown hook can use it to close the file cleanly.
  @visibleForTesting
  Future<void> get writesSettled => _writes;

  /// Applies an engine result and queues the snapshot behind every write that is
  /// still pending, so the newest state always lands last.
  void _apply(GameState next) {
    state = next;
    _write((store, id) => store.saveState(id, next));
  }

  /// Applies an engine result whose write is more than the snapshot: a vote or
  /// quest row, the snapshot, and the log line, in that order.
  void _applyWith(
    GameState next,
    Future<void> Function(MatchStore store, int id) write,
  ) {
    state = next;
    _write(write);
  }

  void _beginNewMatch(GameState next) {
    // A match still running is kept in the history as abandoned; a finished one
    // keeps its result, so Play Again never rewrites a victory as an abort.
    final running = state;
    final previous = running != null && !running.isFinished ? _gameId : null;
    _gameId = null;
    state = next;
    _enqueue((store) async {
      if (previous != null) await store.markAbandoned(previous);
      final id = await store.createMatch(next);
      _gameId = id;
    });
  }

  /// Writes against the current match id, which is assigned by [_enqueue] after
  /// the row is created.
  void _write(Future<void> Function(MatchStore store, int id) write) {
    _enqueue((store) async {
      final id = _gameId;
      if (id == null) return;
      await write(store, id);
    });
  }

  void _enqueue(Future<void> Function(MatchStore store) write) {
    final store = ref.read(matchStoreProvider);
    if (store == null) return;
    _writes = _writes.then((_) => write(store)).catchError((Object _) {
      // Best effort: the live match is unaffected by a failed write.
    });
  }
}

final gameSessionProvider =
    NotifierProvider<GameSessionController, GameState?>(
      GameSessionController.new,
    );
