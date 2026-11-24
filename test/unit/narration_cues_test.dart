import 'package:avalon_companion/core/models/app_settings.dart';
import 'package:avalon_companion/narration_engine/models/narration_instruction.dart';
import 'package:avalon_companion/narration_engine/models/voice_pack.dart';
import 'package:avalon_companion/narration_engine/scripts/round_script.dart';
import 'package:avalon_companion/narration_engine/services/clip_service.dart';
import 'package:avalon_companion/narration_engine/services/narration_clips.dart';
import 'package:avalon_companion/narration_engine/services/narration_cues.dart';
import 'package:avalon_companion/narration_engine/services/tts_service.dart';
import 'package:avalon_companion/narration_engine/services/voice_pack_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

/// The round lines are announced by the app, not by the MC, so the rule that
/// matters is: the recorded voice is tried first, the phone's voice only stands
/// in for a line that voice did not record, and nothing can throw at the table.
void main() {
  late _RecordingClips clips;
  late _RecordingTts tts;

  setUp(() {
    clips = _RecordingClips();
    tts = _RecordingTts();
  });

  NarrationCues cuesFor({
    VoicePack? pack,
    NarrationLanguage language = NarrationLanguage.english,
  }) => NarrationCues(
    clips: clips,
    tts: tts,
    settings: AppSettings(defaultLanguage: language, volume: 0.5),
    pack: pack ?? VoicePackCatalogue.classic,
  );

  group('a recorded line', () {
    test('plays the recording, not the phone voice', () async {
      await cuesFor().play(RoundScript.approved);

      expect(clips.played, [
        '${NarrationClips.directory}/en/vote.approved.mp3',
      ]);
      expect(tts.spoken, isEmpty);
    });

    test('plays the Filipino folder when the table hears Filipino', () async {
      await cuesFor(language: NarrationLanguage.filipino).play(
        RoundScript.questSuccess,
      );

      expect(clips.played, [
        '${NarrationClips.directory}/fil/quest.success.mp3',
      ]);
    });

    test('falls back to speech when the player cannot open the file', () async {
      clips.fails = true;

      await cuesFor().play(RoundScript.assassination);

      expect(clips.played, hasLength(1));
      expect(tts.spoken, [RoundScript.assassination.english]);
      expect(tts.locales, ['en-GB']);
    });
  });

  group('a voice that did not record the line', () {
    test('speaks the line with the phone voice instead of going silent', () async {
      // A half-finished voice: the night is recorded, the round is not.
      const partial = VoicePack(
        id: 'partial',
        name: 'Partial',
        root: NarrationClips.directory,
        clips: {
          'en': {'night.end'},
          'fil': {'night.end'},
        },
      );

      await cuesFor(pack: partial).play(RoundScript.questFail);

      expect(clips.played, isEmpty);
      expect(tts.spoken, [RoundScript.questFail.english]);
    });

    test('stays quiet when the phone has no voice either', () async {
      tts.available = false;
      const empty = VoicePack(
        id: 'empty',
        name: 'Empty',
        root: NarrationClips.directory,
        clips: {},
      );

      await cuesFor(pack: empty).play(RoundScript.proposal);

      expect(clips.played, isEmpty);
      expect(tts.spoken, isEmpty);
    });
  });

  group('the vote outcome', () {
    test('an approval says the quest begins', () {
      expect(
        NarrationCues.voteOutcome(approved: true, rejectionCount: 0).id,
        'vote.approved',
      );
    });

    test('a rejection that leaves one more warns the table', () {
      expect(
        NarrationCues.voteOutcome(approved: false, rejectionCount: 4).id,
        'vote.rejection_warning',
      );
    });

    test('an ordinary rejection passes the token on', () {
      for (final count in [1, 2, 3]) {
        expect(
          NarrationCues.voteOutcome(approved: false, rejectionCount: count).id,
          'vote.rejected',
          reason: 'rejection $count is not the warning yet',
        );
      }
    });
  });
}

class _RecordingClips implements ClipService {
  final played = <String>[];

  /// Simulates a recording the player could not open.
  bool fails = false;

  @override
  bool get isAvailable => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> play(String assetPath, {required double volume}) async {
    played.add(assetPath);
    return !fails;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _RecordingTts implements TtsService {
  final spoken = <String>[];
  final locales = <String>[];

  /// Whether the phone has a speech engine at all.
  bool available = true;

  /// Whether the chosen language has an installed voice.
  bool languageInstalled = true;

  @override
  bool get isAvailable => available;

  @override
  String? get unavailableReason => available ? null : 'no engine';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isLanguageAvailable(String locale) async =>
      available && languageInstalled;

  @override
  Future<List<TtsVoice>> voices(String locale) async => const [];

  @override
  Future<bool> speak(
    String text, {
    required String locale,
    required double rate,
    required double volume,
    required double pitch,
    String? voiceId,
  }) async {
    spoken.add(text);
    locales.add(locale);
    return true;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
