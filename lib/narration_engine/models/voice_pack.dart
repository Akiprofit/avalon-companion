import '../services/narration_clips.dart';
import 'narration_instruction.dart';

/// One narrator voice: a named set of recordings, one file per instruction id.
///
/// A voice is a *pack*, not a single file. The night is fourteen separate
/// lines, and a pack answers for each of them on its own, so a half-finished
/// voice still works: the lines it has no recording for fall back to the
/// phone's text-to-speech engine, one line at a time.
///
/// [root] is either an asset folder (`assets/audio/voices/dahlia`) or an
/// absolute directory in app storage when the MC imported the pack as a zip.
/// Both are read the same way: `<root>/<en|fil>/<id>.mp3`.
class VoicePack {
  const VoicePack({
    required this.id,
    required this.name,
    required this.root,
    required this.clips,
    this.builtIn = false,
    this.hidden = false,
  });

  /// Stable key, and the folder name: `classic` for the recordings that ship
  /// with the app, otherwise the imported folder on disk.
  final String id;

  /// What the MC sees. Renaming a voice only changes this, never the folder.
  final String name;

  final String root;

  /// Recorded line ids per language folder (`en`, `fil`).
  final Map<String, Set<String>> clips;

  /// True for the recordings bundled in the APK: they can be hidden or
  /// renamed, never deleted, because the files are inside the installed app.
  final bool builtIn;

  /// Hidden voices keep working for a match in progress but are out of the
  /// way in settings.
  final bool hidden;

  bool hasClip(String lineId, NarrationLanguage language) =>
      clips[NarrationClips.folderFor(language)]?.contains(lineId) ?? false;

  int clipCount(NarrationLanguage language) =>
      clips[NarrationClips.folderFor(language)]?.length ?? 0;

  /// The path of [lineId] for [language], or null when this voice did not
  /// record it — the caller then speaks the line with the fallback engine.
  String? pathFor(String lineId, NarrationLanguage language) {
    if (!hasClip(lineId, language)) return null;
    return '$root/${NarrationClips.folderFor(language)}/$lineId.mp3';
  }

  /// Every line id this voice can play in either language.
  Set<String> get recordedIds => {
    for (final set in clips.values) ...set,
  };

  VoicePack copyWith({
    String? name,
    String? root,
    Map<String, Set<String>>? clips,
    bool? builtIn,
    bool? hidden,
  }) {
    return VoicePack(
      id: id,
      name: name ?? this.name,
      root: root ?? this.root,
      clips: clips ?? this.clips,
      builtIn: builtIn ?? this.builtIn,
      hidden: hidden ?? this.hidden,
    );
  }
}
