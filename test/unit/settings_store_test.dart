import 'dart:io';

import 'package:avalon_companion/core/models/app_settings.dart';
import 'package:avalon_companion/database/app_database.dart';
import 'package:avalon_companion/database/repositories/settings_repository.dart';
import 'package:avalon_companion/narration_engine/models/narration_instruction.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

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
    bool soundEffects = true,
    int discussion = 300,
    int players = 5,
    String kingSelection = 'manual',
    int extraDelayMs = 0,
    bool teamVote = true,
    bool bigTable = false,
    String? pack,
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
      soundEffects: soundEffects,
      discussionSeconds: discussion,
      defaultPlayerCount: players,
      mcPinEnabled: false,
      mcPinHash: null,
      kingSelection: kingSelection,
      narratorExtraDelayMs: extraDelayMs,
      teamVoteEnabled: teamVote,
      bigTableEnabled: bigTable,
      voicePackId: pack,
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
      soundEffects: false,
      narratorVoiceId: 'en-gb-x-gba-local',
      narratorPackId: 'voice-of-dahlia',
      narratorExtraDelay: Duration(seconds: 7),
      discussionSeconds: 420,
      defaultPlayerCount: 8,
      kingSelectionMode: KingSelectionMode.automatic,
      teamVoteEnabled: false,
      bigTable: true,
    );

    final companion = SettingsRepository.encode(saved);
    expect(companion.id.value, 1);
    expect(companion.narrationLanguage.value, 'filipino');
    expect(companion.narrationSpeed.value, 1.2);
    expect(companion.narrationPitch.value, 0.75);
    expect(companion.volume.value, 0.35);
    expect(companion.voiceId.value, 'en-gb-x-gba-local');
    expect(companion.autoAdvance.value, true);
    expect(companion.ambientAudioEnabled.value, true);
    expect(companion.keepScreenAwake.value, false);
    expect(companion.confirmations.value, false);
    expect(companion.haptics.value, false);
    expect(companion.soundEffects.value, false);
    expect(companion.discussionSeconds.value, 420);
    expect(companion.defaultPlayerCount.value, 8);
    expect(companion.kingSelection.value, 'automatic');
    expect(companion.narratorExtraDelayMs.value, 7000);
    expect(companion.teamVoteEnabled.value, false);
    expect(companion.bigTableEnabled.value, true);
    expect(companion.voicePackId.value, 'voice-of-dahlia');

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
        soundEffects: false,
        discussion: 420,
        players: 8,
        kingSelection: 'automatic',
        extraDelayMs: 7000,
        teamVote: false,
        bigTable: true,
        pack: 'voice-of-dahlia',
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
    expect(decoded.soundEffects, isFalse);
    expect(decoded.discussionSeconds, 420);
    expect(decoded.defaultPlayerCount, 8);
    expect(decoded.kingSelectionMode, KingSelectionMode.automatic);
    expect(decoded.narratorExtraDelay, const Duration(seconds: 7));
    expect(decoded.teamVoteEnabled, isFalse);
    expect(decoded.bigTable, isTrue);
    expect(
      decoded.narratorPackId,
      'voice-of-dahlia',
      reason: 'the chosen narrator voice survives a restart',
    );
  });

  test('an unknown King mode falls back to the manual wheel', () {
    final decoded = SettingsRepository.decode(record(kingSelection: 'klingon'));
    expect(decoded.kingSelectionMode, KingSelectionMode.manual);
  });

  test('an unknown language falls back to English instead of failing', () {
    final decoded = SettingsRepository.decode(record(language: 'klingon'));
    expect(decoded.defaultLanguage, NarrationLanguage.english);
  });

  test('the stored row holds no readable PIN and no player data', () {
    final columns = record().toColumns(false).keys.toList();
    expect(columns, isNot(contains('pin')));
    expect(
      columns,
      contains('mc_pin_hash'),
      reason: 'only a salted digest is stored, never the digits',
    );
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
    expect(defaults.haptics, isTrue);
    expect(defaults.soundEffects, isTrue);
    expect(defaults.narratorVoiceId, isNull);
    expect(defaults.kingSelectionMode, KingSelectionMode.manual);
    expect(defaults.narratorExtraDelay, Duration.zero);
    expect(defaults.kingsDrawnAutomatically, isFalse);
    expect(
      defaults.teamVoteEnabled,
      isTrue,
      reason: 'the base game votes unless the MC turns it off',
    );
    expect(
      defaults.bigTable,
      isFalse,
      reason: 'a fresh install offers only the rulebook sizes',
    );
  });

  test('a version 4 database gains the vote switch, switched on', () async {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'avalon_vote_migration.db',
    );
    if (await file.exists()) await file.delete();

    // Build a real database with the current schema, write a row, then wind it
    // back to v4: drop the columns and the table v5–v8 added and reset the
    // version stamp. Reopening it is what runs the migration, exactly as an
    // upgraded install does.
    final before = AppDatabase(NativeDatabase(file));
    await before
        .into(before.settings)
        .insert(
          SettingsRepository.encode(
            const AppSettings(discussionSeconds: 420, teamVoteEnabled: false),
          ),
        );
    await before.close();

    sqlite3.open(file.path)
      ..execute('ALTER TABLE settings DROP COLUMN team_vote_enabled')
      ..execute('ALTER TABLE settings DROP COLUMN big_table_enabled')
      ..execute('ALTER TABLE games DROP COLUMN quest_teams')
      ..execute('ALTER TABLE settings DROP COLUMN voice_pack_id')
      ..execute('DROP TABLE voice_packs')
      ..execute('PRAGMA user_version = 4')
      ..close();

    final after = AppDatabase(NativeDatabase(file));
    addTearDown(() async {
      await after.close();
      if (await file.exists()) await file.delete();
    });

    final migrated = await SettingsRepository(after).load();
    expect(
      migrated.teamVoteEnabled,
      isTrue,
      reason: 'a table that predates the switch keeps the base game rule',
    );
    expect(
      migrated.discussionSeconds,
      420,
      reason: 'the rest of the saved row is untouched',
    );
    expect(
      migrated.bigTable,
      isFalse,
      reason: 'an upgraded install keeps the rulebook ceiling until asked',
    );
  });
}
