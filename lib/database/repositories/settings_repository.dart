import 'package:drift/drift.dart';

import '../../core/models/table_role.dart';
import '../../features/settings/settings_controller.dart';
import '../../narration_engine/models/narration_instruction.dart';
import '../app_database.dart';

/// Reads and writes the single `Settings` row (id = 1).
///
/// The table stores preferences only — no player, no role, and no readable PIN:
/// `mc_pin_hash` is a salted digest (`PinRepository`), never the digits.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// The stored preferences, or the app defaults when nothing is saved yet.
  Future<AppSettings> load() async {
    final row = await (_db.select(_db.settings)
          ..where((s) => s.id.equals(1)))
        .getSingleOrNull();
    return row == null ? const AppSettings() : decode(row);
  }

  /// Upserts the row, so the first save and every later one take this path.
  ///
  /// Written as update-then-insert rather than `insertOnConflictUpdate`: the
  /// table has no primary key to conflict on and older databases were created
  /// without one, so this stays correct for both.
  Future<void> save(AppSettings settings) {
    return _db.transaction(() async {
      final companion = encode(settings);
      final updated = await (_db.update(_db.settings)
            ..where((s) => s.id.equals(1)))
          .write(companion);
      if (updated == 0) {
        await _db.into(_db.settings).insert(companion);
      }
    });
  }

  /// Pure mapping, so the stored shape can be tested without a database.
  static SettingsCompanion encode(AppSettings settings) {
    return SettingsCompanion.insert(
      id: 1,
      narrationLanguage: Value(settings.defaultLanguage.name),
      narrationSpeed: Value(settings.narrationRate),
      narrationPitch: Value(settings.narrationPitch),
      volume: Value(settings.volume),
      voiceId: Value(settings.narratorVoiceId),
      voicePackId: Value(settings.narratorPackId),
      ambientAudioEnabled: Value(settings.ambientAudio),
      autoAdvance: Value(settings.autoAdvance),
      keepScreenAwake: Value(settings.keepScreenAwake),
      confirmations: Value(settings.confirmations),
      haptics: Value(settings.haptics),
      soundEffects: Value(settings.soundEffects),
      discussionSeconds: Value(settings.discussionSeconds),
      defaultPlayerCount: Value(settings.defaultPlayerCount),
      kingSelection: Value(settings.kingSelectionMode.name),
      narratorExtraDelayMs: Value(settings.narratorExtraDelay.inMilliseconds),
      teamVoteEnabled: Value(settings.teamVoteEnabled),
      bigTableEnabled: Value(settings.bigTable),
      tableRole: Value(settings.tableRole.name),
    );
  }

  /// Pure mapping back to the app model, tolerant of a newer stored value.
  static AppSettings decode(SettingsRecord row) {
    return AppSettings(
      defaultLanguage: NarrationLanguage.values.firstWhere(
        (language) => language.name == row.narrationLanguage,
        orElse: () => NarrationLanguage.english,
      ),
      narrationRate: row.narrationSpeed,
      narrationPitch: row.narrationPitch,
      volume: row.volume,
      autoAdvance: row.autoAdvance,
      ambientAudio: row.ambientAudioEnabled,
      narratorVoiceId: row.voiceId,
      narratorPackId: row.voicePackId,
      keepScreenAwake: row.keepScreenAwake,
      confirmations: row.confirmations,
      haptics: row.haptics,
      soundEffects: row.soundEffects,
      discussionSeconds: row.discussionSeconds,
      defaultPlayerCount: row.defaultPlayerCount,
      kingSelectionMode: KingSelectionMode.fromStorage(row.kingSelection),
      narratorExtraDelay: Duration(
        milliseconds: row.narratorExtraDelayMs.clamp(0, 30000),
      ),
      teamVoteEnabled: row.teamVoteEnabled,
      bigTable: row.bigTableEnabled,
      tableRole: TableRole.fromStorage(row.tableRole),
    );
  }
}
