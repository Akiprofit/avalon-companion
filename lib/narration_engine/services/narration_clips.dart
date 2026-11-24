import '../models/narration_instruction.dart';

/// The recorded narrator lines shipped inside the app.
///
/// One MP3 per instruction id, per language, in
/// `assets/audio/narration/<voice>/<en|fil>/<id>.mp3`. A line listed here is
/// spoken from its recording; anything else falls back to the platform
/// text-to-speech engine, so a missing file degrades to a voice rather than
/// silence.
///
/// The recordings ship under the voice that made them, so another narrator's
/// folder can sit beside `Dahlia voices/` in `assets/audio/narration/`. Only
/// [voice] is bundled as the app's narrator today; extra voices are added under
/// `assets/audio/voices/` and appear in Settings.
///
/// Keep this set in step with the files: `test/unit/narration_clips_test.dart`
/// fails when a recording is missing, and when an id here has no matching line
/// in [NightScript] or [RoundScript].
abstract final class NarrationClips {
  /// The folder this app bundles as its narrator, inside [narratorDirectory].
  static const voice = 'Dahlia voices';

  static const narratorDirectory = 'assets/audio/narration';

  static const directory = '$narratorDirectory/$voice';

  /// Every line the narrator speaks — the fourteen night lines and the seven
  /// round lines — recorded in both languages.
  static const ids = <String>{
    'night.close_eyes',
    'night.evil.wake',
    'night.evil.look',
    'night.evil.look_oberon',
    'night.evil.sleep',
    'night.merlin.wake',
    'night.merlin.look',
    'night.merlin.look_mordred',
    'night.merlin.sleep',
    'night.percival.wake',
    'night.percival.look',
    'night.percival.look_alone',
    'night.percival.sleep',
    'night.end',
    'round.proposal',
    'vote.approved',
    'vote.rejected',
    'vote.rejection_warning',
    'quest.success',
    'quest.fail',
    'assassination.begin',
  };

  static bool has(String id) => ids.contains(id);

  /// The bundle path of [id] in [language].
  static String assetFor(String id, NarrationLanguage language) =>
      '$directory/${folderFor(language)}/$id.mp3';

  static String folderFor(NarrationLanguage language) =>
      language == NarrationLanguage.filipino ? 'fil' : 'en';
}
