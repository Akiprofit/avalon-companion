import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// A saved match — master plan PART 8, `Games`.
///
/// Every column is public game state. There is no character or allegiance
/// column on a player anywhere in this schema, by design (master plan §2.2).
@DataClassName('GameRecord')
class Games extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// UTC milliseconds since epoch.
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  IntColumn get playerCount => integer()();

  /// `inProgress`, `finished` or `abandoned`.
  TextColumn get status => text()();

  /// `good`, `evil`, or null while the match runs.
  TextColumn get winner => text().nullable()();

  IntColumn get durationSeconds => integer().nullable()();

  /// Current phase code, so an interrupted match resumes where it stopped.
  TextColumn get phase => text()();

  /// Phase to return to after a pause; null when not paused.
  TextColumn get pausedFrom => text().nullable()();

  IntColumn get leaderSeat => integer()();
  IntColumn get questNumber => integer()();
  IntColumn get rejectionCount => integer()();

  /// Seats on the current proposal, comma joined and ascending. Empty outside a
  /// proposal. Keeping it lets an interrupted vote resume with the team shown.
  TextColumn get currentTeam => text().withDefault(const Constant(''))();

  /// Quest outcomes in order, comma joined: `success,fail`.
  TextColumn get questResults => text()();

  /// Characters in play, as a JSON object of character code to count. The list
  /// is public configuration and is never attached to a player.
  TextColumn get composition => text()();

  /// `threeQuests`, `fiveRejections`, `assassination`, or null.
  TextColumn get winReason => text().nullable()();

  /// `identified` or `notIdentified` — never a named player.
  TextColumn get assassinationOutcome => text().nullable()();
}

/// Seats at the table — master plan PART 8, `Players`. Name and seat only.
@DataClassName('PlayerRecord')
@TableIndex(name: 'players_game_id', columns: {#gameId})
@TableIndex(name: 'players_seat', columns: {#seatNumber})
class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();
  TextColumn get displayName => text()();
  IntColumn get seatNumber => integer()();
}

/// One resolved quest — master plan PART 8, `Quests`.
@DataClassName('QuestRecord')
@TableIndex(name: 'quests_game_id', columns: {#gameId})
@TableIndex(name: 'quests_number', columns: {#questNumber})
class Quests extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();
  IntColumn get questNumber => integer()();
  IntColumn get requiredPlayers => integer()();
  IntColumn get successCount => integer()();
  IntColumn get failCount => integer()();

  /// `success` or `fail`.
  TextColumn get result => text()();
}

/// One resolved team vote — master plan PART 8, `TeamProposals`.
@DataClassName('ProposalRecord')
@TableIndex(name: 'proposals_game_id', columns: {#gameId})
@TableIndex(name: 'proposals_number', columns: {#questNumber})
class TeamProposals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();
  IntColumn get questNumber => integer()();
  IntColumn get leaderSeat => integer()();

  /// Seats on the proposed team, comma joined and ascending.
  TextColumn get selectedSeats => text()();
  IntColumn get approveCount => integer()();
  IntColumn get rejectCount => integer()();

  /// `approved` or `rejected`.
  TextColumn get result => text()();
}

/// The public log of a match — master plan PART 8, `GameEvents`.
@DataClassName('EventRecord')
@TableIndex(name: 'events_game_id', columns: {#gameId})
class GameEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();
  TextColumn get eventType => text()();
  TextColumn get eventDescription => text()();

  /// UTC milliseconds since epoch.
  IntColumn get createdAt => integer()();
}

/// One row, id = 1 — master plan PART 8, `Settings`.
///
/// `mc_pin_hash` holds a salted SHA-256 of the optional MC PIN, never the PIN
/// itself: the app only needs to answer "is this the same PIN?".
@DataClassName('SettingsRecord')
class Settings extends Table {
  IntColumn get id => integer()();
  TextColumn get narrationLanguage =>
      text().withDefault(const Constant('english'))();
  RealColumn get narrationSpeed => real().withDefault(const Constant(0.9))();
  RealColumn get narrationPitch => real().withDefault(const Constant(0.92))();
  RealColumn get volume => real().withDefault(const Constant(0.8))();
  TextColumn get voiceId => text().nullable()();
  BoolColumn get ambientAudioEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get autoAdvance => boolean().withDefault(const Constant(false))();
  BoolColumn get keepScreenAwake =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get confirmations => boolean().withDefault(const Constant(true))();
  BoolColumn get haptics => boolean().withDefault(const Constant(true))();
  BoolColumn get soundEffects => boolean().withDefault(const Constant(true))();
  IntColumn get discussionSeconds =>
      integer().withDefault(const Constant(300))();
  IntColumn get defaultPlayerCount =>
      integer().withDefault(const Constant(5))();
  BoolColumn get mcPinEnabled => boolean().withDefault(const Constant(false))();

  /// Salted SHA-256 of the MC PIN as `salt:hash`; null when no PIN is set.
  ///
  /// A four-digit PIN is a lock on the table, not a password vault: this keeps
  /// it out of plain sight in the file and off every screen. See
  /// `PinRepository`.
  TextColumn get mcPinHash => text().nullable()();

  /// `automatic` or `manual` — whether the wheel draws a King every round.
  TextColumn get kingSelection =>
      text().withDefault(const Constant('manual'))();

  /// Extra silence after each spoken narration line, in milliseconds.
  IntColumn get narratorExtraDelayMs =>
      integer().withDefault(const Constant(0))();
}

@DriftDatabase(
  tables: [Games, Players, Quests, TeamProposals, GameEvents, Settings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2 added the current proposal, so an interrupted vote can be restored.
      if (from < 2) {
        await m.addColumn(games, games.currentTeam);
      }
      // v3 added the sound-effects switch and the optional MC PIN hash.
      if (from < 3) {
        await m.addColumn(settings, settings.soundEffects);
        await m.addColumn(settings, settings.mcPinHash);
      }
      // v4 added the King selection mode and the narration extra delay.
      if (from < 4) {
        await m.addColumn(settings, settings.kingSelection);
        await m.addColumn(settings, settings.narratorExtraDelayMs);
      }
    },
    beforeOpen: (details) async {
      // CASCADE deletes rely on this; drift does not enable it for us.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
