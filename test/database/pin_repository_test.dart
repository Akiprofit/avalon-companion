import 'package:avalon_companion/core/models/app_settings.dart';
import 'package:avalon_companion/database/app_database.dart';
import 'package:avalon_companion/database/repositories/pin_repository.dart';
import 'package:avalon_companion/database/repositories/settings_repository.dart';
import 'package:avalon_companion/narration_engine/models/narration_instruction.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 10 gate: the PIN lives in the real `Settings` row as a digest, and
/// everything else in that row keeps working while it is set and cleared.
void main() {
  late AppDatabase db;
  late PinRepository pins;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    pins = PinRepository(db);
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  test('no PIN is stored on a fresh database', () async {
    expect(await pins.loadHash(), isNull);
  });

  test('a saved PIN round-trips as a digest and matches only itself', () async {
    await pins.save('4821');

    final stored = await pins.loadHash();
    expect(stored, isNotNull);
    expect(stored!.contains('4821'), isFalse);
    expect(PinRepository.matches('4821', stored), isTrue);
    expect(PinRepository.matches('4822', stored), isFalse);
  });

  test('saving a PIN creates the row when settings were never saved', () async {
    // The first write to `Settings` in the app's life can be the PIN itself.
    await pins.save('1357');
    final hash = await pins.loadHash();
    expect(hash, isNotNull);

    final row = await (db.select(db.settings)).getSingle();
    expect(row.id, 1);
    expect(row.mcPinEnabled, isTrue);
    expect(row.mcPinHash, hash);
    // The column defaults fill the rest of a freshly created row.
    expect(row.confirmations, isTrue);
    expect(row.keepScreenAwake, isTrue);
    expect(row.soundEffects, isTrue);
  });

  test('clearing the PIN keeps the rest of the settings', () async {
    const saved = AppSettings(
      defaultLanguage: NarrationLanguage.filipino,
      discussionSeconds: 480,
      haptics: false,
      soundEffects: false,
    );
    await settings.save(saved);
    await pins.save('2468');

    await pins.clear();

    expect(await pins.loadHash(), isNull);
    final reloaded = await settings.load();
    expect(reloaded.defaultLanguage, NarrationLanguage.filipino);
    expect(reloaded.discussionSeconds, 480);
    expect(reloaded.haptics, isFalse);
    expect(reloaded.soundEffects, isFalse);
  });

  test('replacing a PIN forgets the old one', () async {
    await pins.save('1111');
    await pins.save('2222');

    final stored = await pins.loadHash();
    expect(stored, isNotNull);
    expect(PinRepository.matches('1111', stored!), isFalse);
    expect(PinRepository.matches('2222', stored), isTrue);
  });
}
