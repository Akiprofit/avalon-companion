import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/app_settings.dart';
import 'app_database.dart';
import 'repositories/game_repository.dart';
import 'repositories/pin_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/voice_pack_repository.dart';

/// Opens the on-device SQLite file. Called once, from `bootstrap()`.
///
/// The name is fixed: one database, one user, no accounts (master plan PART 8).
AppDatabase openAppDatabase() =>
    AppDatabase(driftDatabase(name: 'avalon_companion'));

/// The open database, or null when the app is running without one.
///
/// `bootstrap()` overrides this with the real database. Everything that touches
/// storage treats null as "persistence unavailable" and keeps working, which is
/// what lets widget tests run with no SQLite library and lets a device with a
/// locked file still play a match.
final appDatabaseProvider = Provider<AppDatabase?>((ref) => null);

/// The match store. Null when there is no database.
final matchStoreProvider = Provider<MatchStore?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db == null ? null : GameRepository(db);
});

/// The settings store. Null when there is no database.
final settingsStoreProvider = Provider<SettingsRepository?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db == null ? null : SettingsRepository(db);
});

/// The MC PIN store. Null when there is no database, which also means no PIN.
final pinStoreProvider = Provider<PinRepository?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db == null ? null : PinRepository(db);
});

/// The narrator voice store. Null when there is no database, which leaves the
/// bundled recordings as the only voice — the app still narrates.
final voicePackStoreProvider = Provider<VoicePackRepository?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db == null ? null : VoicePackRepository(db);
});

/// Settings read before the first frame, so the first narration already uses
/// the stored language and speed instead of flashing the defaults.
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);

/// The stored MC PIN hash (`rounds$salt$digest`), read before the first frame.
///
/// Null when no PIN is set. Kept out of `AppSettings` on purpose: settings are
/// copied into UI state, and the PIN should never travel with them.
final initialPinHashProvider = Provider<String?>((ref) => null);

/// A match that was running when the app last closed, offered as Continue Game.
final restoredMatchProvider = Provider<StoredMatch?>((ref) => null);
