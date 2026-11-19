import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/core/constants/routes.dart';
import 'package:avalon_companion/database/database_provider.dart';
import 'package:avalon_companion/features/settings/settings_controller.dart';
import 'package:avalon_companion/features/settings/voice_pack_picker.dart';
import 'package:avalon_companion/narration_engine/controllers/voice_packs_controller.dart';
import 'package:avalon_companion/narration_engine/models/narration_instruction.dart';
import 'package:avalon_companion/narration_engine/models/voice_pack.dart';
import 'package:avalon_companion/narration_engine/services/clip_provider.dart';
import 'package:avalon_companion/narration_engine/services/clip_service.dart';
import 'package:avalon_companion/narration_engine/services/voice_files.dart';
import 'package:avalon_companion/narration_engine/services/voice_pack_catalogue.dart';
import 'package:avalon_companion/narration_engine/services/voice_providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The imported voice every test in this file works with: two English lines
/// and one Filipino line, so the coverage label has something to count.
const _dahlia = VoicePack(
  id: 'voice-of-dahlia',
  name: 'Voice of Dahlia',
  root: '/data/voices/voice-of-dahlia',
  clips: {
    'en': {'night.close_eyes', 'night.evil.wake'},
    'fil': {'night.close_eyes'},
  },
);

/// A fixed voice list, so the tests never read the asset manifest.
class _FixedVoices extends VoicePacksController {
  @override
  VoicePacksState build() => VoicePacksState(
    packs: [VoicePackCatalogue.classic, _dahlia],
    loaded: true,
  );

  @override
  Future<void> refresh() async {}
}

/// Keeps the widget tests off the disk: a real `File.exists` never finishes
/// inside the fake async zone, which is not what the screen is being tested for.
class _NoFiles extends VoiceFiles {
  const _NoFiles();

  @override
  Future<void> delete(String root) async {}

  @override
  Future<void> discardCopy(String zipPath) async {}
}

/// Records what the sample button asked to play, completing at once so the
/// test never waits for audio.
class _RecordingClips implements ClipService {
  final played = <String>[];
  var stops = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> play(String assetPath, {required double volume}) async {
    played.add(assetPath);
    return true;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async {}
}

/// The MC changes the narrator between matches, from Settings. The list is the
/// whole surface: pick a voice, rename it, hide it, delete an imported one.
void main() {
  Future<ProviderContainer> pumpSettings(
    WidgetTester tester, {
    AppSettings settings = const AppSettings(),
    ClipService? clips,
  }) async {
    tester.view.physicalSize = const Size(1242, 9000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSettingsProvider.overrideWithValue(settings),
          voicePacksProvider.overrideWith(_FixedVoices.new),
          voiceFilesProvider.overrideWithValue(const _NoFiles()),
          if (clips != null) clipServiceProvider.overrideWithValue(clips),
        ],
        child: const AvalonApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AvalonApp)),
    );
    final router =
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
            as GoRouter;
    router.goNamed(RouteNames.settings);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('settings names the voice in use and how much it covers', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      settings: const AppSettings(narratorPackId: 'voice-of-dahlia'),
    );

    expect(find.text('Narrator voice'), findsOneWidget);
    expect(find.text('Voice of Dahlia'), findsOneWidget);
    expect(
      find.text('English 2/14 · Filipino 1/14'),
      findsOneWidget,
      reason: 'a partial voice is allowed, so the counts are shown',
    );
  });

  testWidgets('the picker lists every voice and switches the narrator', (
    tester,
  ) async {
    final container = await pumpSettings(
      tester,
      settings: const AppSettings(narratorPackId: 'voice-of-dahlia'),
    );

    await tester.tap(find.byKey(const Key('settings_voice_pack')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('voice_pack_classic')), findsOneWidget);
    expect(
      find.byKey(const Key('voice_pack_voice-of-dahlia')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('voice_pack_classic')));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).narratorPackId, 'classic');
    expect(
      find.byKey(const Key('settings_voice_pack')),
      findsOneWidget,
      reason: 'the picker closes back onto settings',
    );
  });

  testWidgets('the sample button plays the voice in the table language', (
    tester,
  ) async {
    final clips = _RecordingClips();
    await pumpSettings(tester, clips: clips);

    await tester.tap(find.byKey(const Key('settings_voice_pack')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('voice_pack_sample_classic')));
    await tester.pumpAndSettle();

    expect(
      clips.played,
      ['assets/audio/narration/Dahlia voices/en/night.close_eyes.mp3'],
      reason: 'the first night line, from the shipped voice',
    );

    await tester.tap(
      find.byKey(const Key('voice_pack_sample_voice-of-dahlia')),
    );
    await tester.pumpAndSettle();

    expect(
      clips.played.last,
      '/data/voices/voice-of-dahlia/en/night.close_eyes.mp3',
    );
  });

  testWidgets('a Filipino table samples the Filipino recording', (tester) async {
    final clips = _RecordingClips();
    await pumpSettings(
      tester,
      clips: clips,
      settings: const AppSettings(
        narratorPackId: 'voice-of-dahlia',
        defaultLanguage: NarrationLanguage.filipino,
      ),
    );

    await tester.tap(find.byKey(const Key('settings_voice_pack')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('voice_pack_sample_voice-of-dahlia')),
    );
    await tester.pumpAndSettle();

    expect(
      clips.played.single,
      '/data/voices/voice-of-dahlia/fil/night.close_eyes.mp3',
    );
  });

  test('a voice with nothing in the table language samples the other', () {
    const pack = VoicePack(
      id: 'okley',
      name: 'Okley',
      root: '/voices/okley',
      clips: {
        'fil': {'night.end'},
      },
    );

    expect(
      samplePathFor(pack, NarrationLanguage.english),
      '/voices/okley/fil/night.end.mp3',
    );
    expect(
      samplePathFor(pack, NarrationLanguage.filipino),
      '/voices/okley/fil/night.end.mp3',
    );
    expect(
      samplePathFor(
        VoicePackCatalogue.classic.copyWith(clips: const {}),
        NarrationLanguage.english,
      ),
      isNull,
      reason: 'a voice with no recordings cannot be sampled',
    );
  });

  testWidgets('closing the picker stops the sample', (tester) async {
    final clips = _RecordingClips();
    await pumpSettings(tester, clips: clips);

    await tester.tap(find.byKey(const Key('settings_voice_pack')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voice_pack_sample_classic')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(clips.stops, greaterThan(0));
  });

  testWidgets('a voice can be renamed without touching its files', (
    tester,
  ) async {
    final container = await pumpSettings(
      tester,
      settings: const AppSettings(narratorPackId: 'voice-of-dahlia'),
    );

    await tester.tap(find.byKey(const Key('settings_voice_pack')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('voice_pack_menu_voice-of-dahlia')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename…'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('voice_pack_name_field')),
      'Dahlia at the pub',
    );
    await tester.tap(find.byKey(const Key('voice_pack_name_save')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('voice_pack_voice-of-dahlia')),
        matching: find.text('Dahlia at the pub'),
      ),
      findsOneWidget,
    );
    expect(
      container.read(voicePacksProvider).byId('voice-of-dahlia')!.name,
      'Dahlia at the pub',
    );
    expect(container.read(settingsProvider).narratorPackId, 'voice-of-dahlia');
  });

  testWidgets('deleting the active voice returns to the shipped narrator', (
    tester,
  ) async {
    final container = await pumpSettings(
      tester,
      settings: const AppSettings(narratorPackId: 'voice-of-dahlia'),
    );

    await tester.tap(find.byKey(const Key('settings_voice_pack')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('voice_pack_menu_voice-of-dahlia')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Imported voices are deleted for real, so the confirmation says so.
    expect(find.text('Delete Voice of Dahlia?'), findsOneWidget);
    await tester.tap(find.text('Delete the voice'));
    await tester.pumpAndSettle();

    expect(
      container.read(voicePacksProvider).byId('voice-of-dahlia'),
      isNull,
      reason: 'the row leaves the list',
    );
    expect(
      container.read(settingsProvider).narratorPackId,
      isNull,
      reason: 'deleting the narrator falls back to the shipped recordings',
    );
    expect(find.text('Dahlia'), findsOneWidget);
  });

  testWidgets('a bundled voice is hidden instead of deleted', (tester) async {
    final container = await pumpSettings(
      tester,
      settings: const AppSettings(narratorPackId: 'classic'),
    );

    await tester.tap(find.byKey(const Key('settings_voice_pack')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voice_pack_menu_classic')));
    await tester.pumpAndSettle();

    expect(find.text('Hide'), findsOneWidget);
    expect(
      find.text('Delete'),
      findsNothing,
      reason: 'the MP3s ship inside the APK and cannot be removed',
    );

    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();

    expect(
      container.read(voicePacksProvider).byId('classic')!.hidden,
      isTrue,
    );
    expect(
      container.read(settingsProvider).narratorPackId,
      isNull,
      reason: 'hiding the active voice moves the match back to the default',
    );
  });
}
