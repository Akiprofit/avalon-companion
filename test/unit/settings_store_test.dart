import 'package:avalon_companion/core/models/app_settings.dart';
import 'package:avalon_companion/database/app_database.dart';
import 'package:avalon_companion/database/repositories/settings_repository.dart';
import 'package:avalon_companion/narration_engine/models/narration_instruction.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 9 gate: preferences survive a restart, and nothing secret is stored.
void main() {
  SettingsRecord record({
    String language = 'english',
    double rate = 0.9,
    double pitch = 0.92,
    double volume = 0.8,
    bool ambient = false,
    bool autoAdvance = false,
    bool keepAwake = true,
    bool confirmations = true,
    bool haptics = true,
    int discussion = 300,
    int players = 5,
  }) {
    return SettingsRecord(
      id: 1,
      narrationLanguage: language,
      narrationSpeed: rate,
      narrationPitch: pitch,
      volume: volume,
      voiceId: null,
      ambientAudioEnabled: ambient,
      autoAdvance: autoAdvance,
      keepScreenAwake: keepAwake,
      confirmations: confirmations,
      haptics: haptics,
      discussionSeconds: discussion,
      defaultPlayerCount: players,
      mcPinEnabled: false,
    );
  }

  test('every preference round-trips through the stored row', () {
    const saved = AppSettings(
      defaultLanguage: NarrationLanguage.filipino,
      narrationRate: 1.2,
      narrationPitch: 0.75,
      volume: 0.35,
      autoAdvance: true,
      ambientAudio: true,
      keepScreenAwake: false,
      confirmations: false,
      haptics: false,
      discussionSeconds: 420,
      defaultPlayerCount: 8,
    );

    final companion = SettingsRepository.encode(saved);
    expect(companion.id.value, 1);
    expect(companion.narrationLanguage.value, 'filipino');
    expect(companion.narrationSpeed.value, 1.2);
    expect(companion.narrationPitch.value, 0.75);
    expect(companion.volume.value, 0.35);
    expect(companion.autoAdvance.value, true);
    expect(companion.ambientAudioEnabled.value, true);
    expect(companion.keepScreenAwake.value, false);
    expect(companion.confirmations.value, false);
    expect(companion.haptics.value, false);
    expect(companion.discussionSeconds.value, 420);
    expect(companion.defaultPlayerCount.value, 8);

    final decoded = SettingsRepository.decode(
      record(
        language: 'filipino',
        rate: 1.2,
        pitch: 0.75,
        volume: 0.35,
        ambient: true,
        autoAdvance: true,
        keepAwake: false,
        confirmations: false,
        haptics: false,
        discussion: 420,
        players: 8,
      ),
    );

    expect(decoded.defaultLanguage, NarrationLanguage.filipino);
    expect(decoded.narrationRate, 1.2);
    expect(decoded.narrationPitch, 0.75);
    expect(decoded.volume, 0.35);
    expect(decoded.autoAdvance, isTrue);
    expect(decoded.ambientAudio, isTrue);
    expect(decoded.keepScreenAwake, isFalse);
    expect(decoded.confirmations, isFalse);
    expect(decoded.haptics, isFalse);
    expect(decoded.discussionSeconds, 420);
    expect(decoded.defaultPlayerCount, 8);
  });

  test('an unknown language falls back to English instead of failing', () {
    final decoded = SettingsRepository.decode(record(language: 'klingon'));
    expect(decoded.defaultLanguage, NarrationLanguage.english);
  });

  test('the stored row holds no PIN and no player data', () {
    final columns = record().toColumns(false).keys.toList();
    expect(columns, isNot(contains('pin')));
    expect(
      columns,
      contains('mc_pin_enabled'),
      reason: 'the enabled flag is stored, the PIN itself never is',
    );
    expect(columns.where((c) => c.contains('player')), ['default_player_count']);
  });

  test('defaults are the documented ones', () {
    const defaults = AppSettings();
    expect(defaults.defaultLanguage, NarrationLanguage.english);
    expect(defaults.discussionSeconds, 300);
    expect(defaults.defaultPlayerCount, 5);
    expect(defaults.confirmations, isTrue);
  });
}
