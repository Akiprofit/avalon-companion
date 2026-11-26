import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_settings.dart';
import '../../core/models/table_role.dart';
import '../../database/database_provider.dart';
import '../../game_engine/rules/avalon_tables.dart';
import '../../narration_engine/models/narration_instruction.dart';

export '../../core/models/app_settings.dart';

/// Settings state, seeded from the stored `Settings` row at launch.
///
/// Every change is written straight through to the database; a write failure
/// never blocks the UI, because a preference is not worth losing a match over.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(initialSettingsProvider);

  void update(AppSettings Function(AppSettings current) transform) {
    state = transform(state);
    _persist();
  }

  void setLanguage(NarrationLanguage language) =>
      update((s) => s.copyWith(defaultLanguage: language));

  /// Chooses the recorded narrator; null restores the shipped recordings.
  void setVoicePack(String? packId) => update(
    (s) => packId == null
        ? s.copyWith(clearNarratorPack: true)
        : s.copyWith(narratorPackId: packId),
  );

  void setRate(double rate) =>
      update((s) => s.copyWith(narrationRate: rate.clamp(0.5, 1.5)));

  void setPitch(double pitch) =>
      update((s) => s.copyWith(narrationPitch: pitch.clamp(0.7, 1.2)));

  void setVolume(double volume) =>
      update((s) => s.copyWith(volume: volume.clamp(0.0, 1.0)));

  void setDiscussionSeconds(int seconds) =>
      update((s) => s.copyWith(discussionSeconds: seconds.clamp(60, 1800)));

  void setDefaultPlayerCount(int count) => update(
    (s) => s.copyWith(
      defaultPlayerCount: count.clamp(
        AvalonTables.minPlayers,
        AvalonTables.maxPlayersFor(bigTable: s.bigTable),
      ),
    ),
  );

  /// Unlocks the 11–14 player house tables in setup.
  ///
  /// Turning it off brings a stored default back inside the rulebook's ceiling,
  /// so the next setup cannot seed a count the app no longer offers.
  void setBigTable(bool enabled) => update(
    (s) => s.copyWith(
      bigTable: enabled,
      defaultPlayerCount: enabled
          ? s.defaultPlayerCount
          : s.defaultPlayerCount.clamp(
              AvalonTables.minPlayers,
              AvalonTables.officialMaxPlayers,
            ),
    ),
  );

  void setKingSelectionMode(KingSelectionMode mode) =>
      update((s) => s.copyWith(kingSelectionMode: mode));

  /// Remembers what this device is for, so Home offers the right entry next
  /// launch. It changes no game state and opens no socket.
  void setTableRole(TableRole role) =>
      update((s) => s.copyWith(tableRole: role));

  /// Turns the approval vote on or off for future proposals. Existing matches
  /// are untouched: the rule is read when a team is confirmed.
  void setTeamVoteEnabled(bool enabled) =>
      update((s) => s.copyWith(teamVoteEnabled: enabled));

  /// Extra silence after every narration line; capped so a slide can never
  /// stall the night for longer than half a minute.
  void setNarratorExtraDelay(Duration delay) => update(
    (s) => s.copyWith(
      narratorExtraDelay: Duration(
        milliseconds: delay.inMilliseconds.clamp(0, 20000),
      ),
    ),
  );

  /// Fire-and-forget write. The store is null when the app runs without a
  /// database (tests, or a device where the file could not be opened).
  void _persist() {
    final store = ref.read(settingsStoreProvider);
    if (store == null) return;
    store.save(state).catchError((Object _) {
      // Keep the in-memory preference; the next change retries the write.
    });
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

/// Whether destructive actions ask before proceeding.
final settingsConfirmProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider.select((s) => s.confirmations)),
);
