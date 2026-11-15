import 'package:avalon_companion/core/models/app_settings.dart';
import 'package:avalon_companion/database/app_database.dart';
import 'package:avalon_companion/database/repositories/game_repository.dart';
import 'package:avalon_companion/database/repositories/settings_repository.dart';
import 'package:avalon_companion/game_engine/engine/game_engine.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/models/game_state.dart';
import 'package:avalon_companion/game_engine/models/phase.dart';
import 'package:avalon_companion/game_engine/models/player.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:avalon_companion/narration_engine/models/narration_instruction.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';


/// Phase 9 gate: the real schema stores and returns a match, with no role column
/// and no way for a cascade delete to leave orphans behind.
void main() {
  late AppDatabase db;
  late GameRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = GameRepository(db);
  });

  tearDown(() => db.close());

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

  GameState newGame({int players = 5}) {
    return GameEngine.create(
      players: [
        for (var seat = 1; seat <= players; seat++)
          Player(seat: seat, name: 'Player $seat'),
      ],
      composition: compositionFor(players),
    );
  }

  /// Walks a match to the end of quest one with an approved team.
  GameState resolvedQuestOne() {
    var game = newGame();
    game = GameEngine.startNight(game);
    game = GameEngine.endNight(game);
    game = GameEngine.chooseLord(game, seat: 2);
    game = GameEngine.beginTeamSelection(game);
    game = GameEngine.proposeTeam(game, [1, 2]);
    game = GameEngine.recordVotes(game, approve: 4, reject: 1);
    game = GameEngine.resolveTeamVote(game);
    return GameEngine.recordQuest(game, failCards: 0);
  }

  /// A complete Good victory: three successful quests, Merlin survives.
  GameState goodVictory() {
    var game = GameEngine.startNight(newGame());
    game = GameEngine.endNight(game);
    game = GameEngine.chooseLord(game, seat: 1);
    for (var quest = 0; quest < 3; quest++) {
      game = GameEngine.beginTeamSelection(game);
      game = GameEngine.proposeTeam(game, [
        for (var seat = 1; seat <= game.requiredTeamSize; seat++) seat,
      ]);
      game = GameEngine.recordVotes(game, approve: 5, reject: 0);
      game = GameEngine.resolveTeamVote(game);
      game = GameEngine.recordQuest(game, failCards: 0);
    }
    return GameEngine.resolveAssassination(game, merlinIdentified: false);
  }

  test('a new match is stored with its seats and a starting event', () async {
    final game = newGame();
    final id = await repository.createMatch(game);

    expect(id, greaterThan(0));
    final summaries = await repository.matches();
    expect(summaries.single.playerCount, 5);
    expect(summaries.single.isInProgress, isTrue);

    final events = await repository.events(id);
    expect(events.single.eventType, 'matchStarted');
    expect(events.single.eventDescription, contains('5 players'));
    expect(events.single.eventDescription, isNot(contains('Player 1')));
  });

  test('saving updates the row instead of adding another', () async {
    final id = await repository.createMatch(newGame());
    await repository.saveState(
      id,
      GameEngine.startNight(newGame()),
    );

    final summaries = await repository.matches();
    expect(summaries.length, 1, reason: 'one row per match');

    final stored = await repository.findInProgress();
    expect(stored, isNotNull);
    expect(stored!.id, id);
    expect(stored.state.phase, Phase.night);
    expect(stored.state.players.map((p) => p.name), [
      'Player 1',
      'Player 2',
      'Player 3',
      'Player 4',
      'Player 5',
    ]);
  });

  test('the current proposal survives a save and a reload', () async {
    final id = await repository.createMatch(newGame());
    final day = GameEngine.beginTeamSelection(
      GameEngine.chooseLord(
        GameEngine.endNight(GameEngine.startNight(newGame())),
        seat: 4,
      ),
    );
    await repository.saveState(id, GameEngine.proposeTeam(day, [2, 3]));

    final stored = await repository.findInProgress();
    expect(stored!.state.currentTeam, [2, 3]);
    expect(stored.state.leaderSeat, 4);
    expect(stored.state.requiredTeamSize, 2);
  });

  test('a vote and a quest are appended with their counts', () async {
    final id = await repository.createMatch(newGame());
    final resolved = resolvedQuestOne();
    await repository.saveState(id, resolved);
    await repository.recordProposal(
      gameId: id,
      questNumber: 1,
      leaderSeat: 2,
      seats: [2, 1],
      approve: 4,
      reject: 1,
      verdict: TeamVerdict.approved,
    );
    await repository.recordQuest(
      gameId: id,
      questNumber: 1,
      requiredPlayers: 2,
      failCards: 1,
      result: QuestResult.success,
    );

    final proposals = await repository.proposals(id);
    expect(proposals.single.selectedSeats, '1,2', reason: 'stored sorted');
    expect(proposals.single.approveCount, 4);
    expect(proposals.single.rejectCount, 1);
    expect(proposals.single.result, 'approved');

    final quests = await repository.quests(id);
    expect(quests.single.successCount, 1);
    expect(quests.single.failCount, 1);
    expect(quests.single.result, 'success');

    final events = (await repository.events(id)).map((e) => e.eventType);
    expect(events, contains('teamApproved'));
    expect(events, contains('questSucceeded'));
    expect(
      events.join(' '),
      isNot(contains('Player')),
      reason: 'log lines describe seats, never people',
    );
  });

  test('a finished match is not offered as Continue Game', () async {
    final id = await repository.createMatch(newGame());
    await repository.saveState(id, goodVictory());

    expect(await repository.findInProgress(), isNull);
    final summary = (await repository.matches()).single;
    expect(summary.isFinished, isTrue);
    expect(summary.winner, 'good');
    expect(summary.durationSeconds, isNotNull);
    expect(summary.assassinationOutcome, 'notIdentified');
  });

  test('abandoning keeps the match in the history', () async {
    final id = await repository.createMatch(newGame());
    await repository.markAbandoned(id);

    expect(await repository.findInProgress(), isNull);
    final summary = (await repository.matches()).single;
    expect(summary.isAbandoned, isTrue);
  });

  test('deleting a match removes everything that belonged to it', () async {
    final id = await repository.createMatch(resolvedQuestOne());
    await repository.recordProposal(
      gameId: id,
      questNumber: 1,
      leaderSeat: 1,
      seats: [1, 2],
      approve: 5,
      reject: 0,
      verdict: TeamVerdict.approved,
    );
    await repository.recordQuest(
      gameId: id,
      questNumber: 1,
      requiredPlayers: 2,
      failCards: 0,
      result: QuestResult.success,
    );

    await repository.deleteMatch(id);

    expect(await repository.matches(), isEmpty);
    expect(await repository.events(id), isEmpty);
    expect(await repository.proposals(id), isEmpty);
    expect(await repository.quests(id), isEmpty);
    final seats = await db.select(db.players).get();
    expect(seats, isEmpty, reason: 'the cascade took the seats too');
  });

  test('the newest match comes first in the history', () async {
    final first = await repository.createMatch(newGame());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = await repository.createMatch(newGame(players: 7));

    final summaries = await repository.matches();
    expect(summaries.map((s) => s.id), [second, first]);
  });

  test('settings are upserted, not appended', () async {
    final settings = SettingsRepository(db);
    expect((await settings.load()).defaultPlayerCount, 5);

    await settings.save(
      const AppSettings(
        defaultLanguage: NarrationLanguage.filipino,
        narrationRate: 1.1,
        narrationPitch: 0.8,
        volume: 0.5,
        ambientAudio: true,
        autoAdvance: true,
        keepScreenAwake: false,
        confirmations: false,
        haptics: false,
        discussionSeconds: 600,
        defaultPlayerCount: 7,
      ),
    );

    final loaded = await settings.load();
    expect(loaded.defaultPlayerCount, 7);
    expect(loaded.confirmations, isFalse);

    final rows = await db.select(db.settings).get();
    expect(rows.length, 1, reason: 'a single settings row');
  });

  test('the schema has no place to store a role for a player', () async {
    final columns = await db
        .customSelect("PRAGMA table_info('players')")
        .get();
    final names = columns.map((row) => row.read<String>('name')).toList();
    expect(names, containsAll(['game_id', 'display_name', 'seat_number']));
    for (final forbidden in ['character', 'role', 'allegiance', 'team']) {
      expect(
        names.where((name) => name.contains(forbidden)),
        isEmpty,
        reason: 'no $forbidden column may exist on a player',
      );
    }
  });
}
