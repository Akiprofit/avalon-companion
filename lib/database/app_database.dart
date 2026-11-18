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

  /// The seats that went on each resolved quest, in the same order as
  /// [questResults]: quests joined by `;`, seats by `,` — `1,3;2,4,5`.
  ///
  /// This is public state: it is what the table saw when each team was
  /// approved. It never says who was loyal and who was a minion.
  TextColumn get questTeams => text().withDefault(const Constant(''))();

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

  /// Whether the table votes on every proposed team. Off is a house rule: the
  /// chosen team goes straight to the quest and rejections never count.
  BoolColumn get teamVoteEnabled =>
      boolean().withDefault(const Constant(true))();

  /// The narrator voice the MC chose. Null means the recordings that ship with
  /// the app, so an untouched install needs no row value.
  TextColumn get voicePackId => text().nullable()();
}

/// The narrator voices this device knows about — master plan PART 8.
///
/// A voice is a folder of one MP3 per narration line, in `en/` and `fil/`, plus
/// the name the MC sees. Bundled voices are seeded here on first read so that
/// renaming and hiding them is ordinary storage work; imported voices are rows
/// whose [root] is a directory in app storage.
///
/// Nothing here touches the game: a match never depends on which voice is
/// chosen, and every line falls back to text-to-speech on its own.
@DataClassName('VoicePackRecord')
class VoicePacks extends Table {
  TextColumn get id => text()();

  /// Display name. The folder stays [id] whatever this says.
  TextColumn get name => text()();

  /// Recorded line ids per language folder, as JSON: `{"en":[…],"fil":[…]}`.
  TextColumn get clips => text().withDefault(const Constant('{}'))();

  /// True for the recordings inside the APK: they can be hidden, not deleted.
  BoolColumn get builtIn => boolean().withDefault(const Constant(false))();

  /// Hidden voices stay playable for a match in progress but leave the list.
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  /// Asset folder for a bundled voice, absolute directory for an imported one.
  TextColumn get root => text().withDefault(const Constant(''))();

  /// UTC milliseconds since epoch; orders imported voices in the list.
  IntColumn get createdAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Games,
    Players,
    Quests,
    TeamProposals,
    GameEvents,
    Settings,
    VoicePacks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 7;

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
      // v5 added the team approval vote switch. Existing rows keep voting on.
      if (from < 5) {
        await m.addColumn(settings, settings.teamVoteEnabled);
      }
      // v6 added the team behind each resolved quest for the board review.
      // Older rows cannot recover teams they never stored, so they stay empty.
      if (from < 6) {
        await m.addColumn(games, games.questTeams);
      }
      // v7 added narrator voice packs and the chosen voice. Bundled voices are
      // seeded from the app on first read, so nothing to backfill here.
      if (from < 7) {
        await m.createTable(voicePacks);
        await m.addColumn(settings, settings.voicePackId);
      }
    },
    beforeOpen: (details) async {
      // CASCADE deletes rely on this; drift does not enable it for us.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
