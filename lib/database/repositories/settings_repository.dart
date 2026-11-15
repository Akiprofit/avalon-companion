import 'package:drift/drift.dart';

import '../../features/settings/settings_controller.dart';
import '../../narration_engine/models/narration_instruction.dart';
import '../app_database.dart';

/// Reads and writes the single `Settings` row (id = 1).
///
/// The table stores preferences only — no PIN, no player, no role. The PIN is
/// never written anywhere (master plan §2.2, PART 8).
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
      ambientAudioEnabled: Value(settings.ambientAudio),
      autoAdvance: Value(settings.autoAdvance),
      keepScreenAwake: Value(settings.keepScreenAwake),
      confirmations: Value(settings.confirmations),
      haptics: Value(settings.haptics),
      discussionSeconds: Value(settings.discussionSeconds),
      defaultPlayerCount: Value(settings.defaultPlayerCount),
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
      keepScreenAwake: row.keepScreenAwake,
      confirmations: row.confirmations,
      haptics: row.haptics,
      discussionSeconds: row.discussionSeconds,
      defaultPlayerCount: row.defaultPlayerCount,
    );
  }
}
