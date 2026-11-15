import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_engine.dart';
import '../models/composition.dart';
import '../models/game_state.dart';
import '../models/phase.dart';
import '../models/player.dart';

/// The live match. Every mutation goes through [GameEngine], so an illegal
/// transition is impossible from the UI: it throws instead of corrupting state.
class GameSessionController extends Notifier<GameState?> {
  @override
  GameState? build() => null;

  void start({required List<String> names, required Composition composition}) {
    final players = [
      for (var i = 0; i < names.length; i++)
        Player(seat: i + 1, name: names[i].trim()),
    ];
    state = GameEngine.create(players: players, composition: composition);
  }

  /// Preparation -> Night. Ignored if the night already started, so reopening
  /// the narration screen never rewinds or duplicates the phase change.
  void startNight() {
    final game = state;
    if (game == null || game.phase != Phase.preparation) return;
    state = GameEngine.startNight(game);
  }

  /// Night -> DayDiscussion. Ignored once the night is over.
  void endNight() {
    final game = state;
    if (game == null || game.phase != Phase.night) return;
    state = GameEngine.endNight(game);
  }

  /// Draws the first Lord. The wheel picks the seat; the engine validates it
  /// and moves the table into the day.
  void chooseLord(int seat) {
    final game = state;
    if (game == null || game.phase != Phase.lordSelection) return;
    state = GameEngine.chooseLord(game, seat: seat);
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
    state = GameEngine.create(
      players: [
        for (final player in game.players)
          Player(seat: player.seat, name: player.name),
      ],
      composition: game.composition,
    );
  }

  /// DayDiscussion -> TeamSelection. Ignored when the MC is already choosing,
  /// so reopening the screen never rewinds anything.
  void beginTeamSelection() {
    final game = state;
    if (game == null || game.phase != Phase.dayDiscussion) return;
    state = GameEngine.beginTeamSelection(game);
  }

  /// Sends the chosen seats to the vote. The engine refuses a wrong size.
  void proposeTeam(List<int> seats) {
    final game = state;
    if (game == null) return;
    state = GameEngine.proposeTeam(game, seats);
  }

  /// Records the physical vote. The MC counts hands; the engine refuses totals
  /// that do not account for the whole table.
  void recordVotes({required int approve, required int reject}) {
    final game = state;
    if (game == null || game.phase != Phase.teamVoting) return;
    state = GameEngine.recordVotes(game, approve: approve, reject: reject);
  }

  /// Applies the vote: approval sends the team to the quest, rejection moves
  /// the leader token, and five rejections end the match for evil.
  void resolveTeamVote() {
    final game = state;
    if (game == null || game.phase != Phase.teamVoting) return;
    state = GameEngine.resolveTeamVote(game);
  }

  /// Records the cards played on the approved quest. Only the fail count is
  /// needed: the engine derives the successes from the team size, decides the
  /// quest 4 two-fail rule and moves the match on.
  void recordQuest({required int failCards}) {
    final game = state;
    if (game == null || game.phase != Phase.questResolution) return;
    state = GameEngine.recordQuest(game, failCards: failCards);
  }

  /// Records the accusation. Only the outcome is stored: whether Merlin was
  /// named. The app never asks for, or keeps, the name (master plan §2.2).
  void resolveAssassination({required bool merlinIdentified}) {
    final game = state;
    if (game == null || game.phase != Phase.assassination) return;
    state = GameEngine.resolveAssassination(
      game,
      merlinIdentified: merlinIdentified,
    );
  }

  void togglePause() {
    final game = state;
    if (game == null) return;
    state = game.phase == Phase.paused
        ? GameEngine.resume(game)
        : GameEngine.pause(game);
  }

  void abort() => state = null;
}

final gameSessionProvider =
    NotifierProvider<GameSessionController, GameState?>(
      GameSessionController.new,
    );
