import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/narration_instruction.dart';
import '../models/voice_pack.dart';
import 'narration_clips.dart';

/// Finds the narrator voices on this device.
///
/// There are two places a voice can live, and they are read the same way —
/// `<root>/<en|fil>/<id>.mp3`:
///
/// * **Bundled.** Recordings inside the APK. The shipped narrator is
///   `assets/audio/narration`; extra voices are folders under
///   `assets/audio/voices/<pack>/`.
/// * **Imported.** Recordings the MC unzipped into app storage. Their [root] is
///   an absolute directory, so nothing has to be rebuilt to use them.
///
/// The asset list comes from Flutter's own manifest, which means a voice folder
/// that is bundled but not listed in `pubspec.yaml` is invisible here — exactly
/// how Flutter itself would treat it.
abstract final class VoicePackCatalogue {
  /// The recordings that ship inside the app.
  static const classicId = 'classic';
  static const classicName = 'Avalon narrator';

  /// Extra bundled voices: one folder per voice.
  static const assetDirectory = 'assets/audio/voices';

  /// The name file a pack may carry: `assets/audio/voices/<pack>/voice.json`.
  static const nameFile = 'voice.json';

  static const _languageFolders = {'en', 'fil'};

  /// Words that stay lowercase inside a folder-derived name, so `voice-of-
  /// dahlia` reads as "Voice of Dahlia" rather than "Voice Of Dahlia".
  static const _minorWords = {'a', 'an', 'and', 'of', 'the', 'to'};

  /// The shipped narrator, described without reading the bundle.
  ///
  /// Used before the manifest has loaded and in tests, where it must behave
  /// exactly like today's app: every night line, in both languages.
  static VoicePack get classic => VoicePack(
    id: classicId,
    name: classicName,
    root: NarrationClips.directory,
    builtIn: true,
    clips: {
      for (final language in NarrationLanguage.values)
        NarrationClips.folderFor(language): NarrationClips.ids,
    },
  );

  /// Reads every bundled voice. Never throws: a manifest failure leaves the
  /// shipped narrator in place, so a match can still be narrated.
  static Future<List<VoicePack>> load({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    List<VoicePack> packs;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(assets);
      packs = fromAssets(manifest.listAssets());
    } catch (_) {
      return [classic];
    }

    // A pack may name itself in `voice.json`. Reading it is best effort: the
    // folder name is a perfectly good fallback, and the MC can rename anyway.
    final names = <String, String>{};
    for (final pack in packs) {
      if (pack.id == classicId) continue;
      try {
        final name = nameFromJson(
          await assets.loadString('${pack.root}/$nameFile'),
        );
        if (name != null) names[pack.id] = name;
      } catch (_) {
        // No name file in this pack.
      }
    }
    if (names.isEmpty) return packs;
    return [for (final pack in packs) pack.copyWith(name: names[pack.id])];
  }

  /// Builds the voices from a list of bundled asset paths — pure, so the
  /// parsing is testable without a bundle.
  ///
  /// Unknown files (READMEs, `.gitkeep`, anything not under a language folder)
  /// are ignored rather than guessed at.
  static List<VoicePack> fromAssets(Iterable<String> assets) {
    final clips = <String, Map<String, Set<String>>>{};

    for (final path in assets) {
      final parts = path.split('/');
      if (parts.length < 5) continue;
      if (parts[0] != 'assets' || parts[1] != 'audio') continue;

      if (parts[2] == 'narration') {
        // assets/audio/narration/<lang>/<id>.mp3
        if (parts.length != 5) continue;
        _record(clips, classicId, parts[3], parts[4]);
        continue;
      }

      if (parts[2] != 'voices') continue;

      // assets/audio/voices/<pack>/<lang>/<id>.mp3
      final packId = parts[3];
      if (!isValidId(packId) || parts.length != 6) continue;
      _record(clips, packId, parts[4], parts[5]);
    }

    // A build without the shipped recordings must still behave like the app
    // did before voices existed: claim the recorded set and let the player
    // report the missing file, which falls through to text-to-speech.
    if (!clips.containsKey(classicId)) return [classic];

    final packs = <VoicePack>[
      VoicePack(
        id: classicId,
        name: classicName,
        root: NarrationClips.directory,
        builtIn: true,
        clips: clips[classicId]!,
      ),
    ];

    final extra = clips.keys.where((id) => id != classicId).toList()..sort();
    for (final id in extra) {
      packs.add(
        VoicePack(
          id: id,
          name: displayNameFor(id),
          root: '$assetDirectory/$id',
          builtIn: true,
          clips: clips[id]!,
        ),
      );
    }
    return packs;
  }

  /// Reads a pack's `voice.json` into a display name, or null when the file is
  /// absent or does not say. The MC can always rename the voice in settings.
  static String? nameFromJson(String contents) {
    try {
      final decoded = jsonDecode(contents);
      if (decoded is! Map) return null;
      final name = decoded['name'];
      if (name is! String) return null;
      final trimmed = name.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      return null;
    }
  }

  /// A readable name for a folder id: `voice-of-dahlia` → "Voice of Dahlia".
  static String displayNameFor(String id) {
    final words = id
        .split(RegExp(r'[-_.\s]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return id;
    final out = <String>[];
    for (final word in words) {
      final lower = word.toLowerCase();
      if (out.isNotEmpty && _minorWords.contains(lower)) {
        out.add(lower);
      } else {
        out.add(lower[0].toUpperCase() + lower.substring(1));
      }
    }
    return out.join(' ');
  }

  /// Folder and line ids are lowercase with dots, dashes and underscores only.
  ///
  /// This is what keeps a pack from naming a path that climbs out of its own
  /// directory, so the same rule guards bundled folders and imported zips.
  static bool isValidId(String id) =>
      id.isNotEmpty && RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(id);

  static void _record(
    Map<String, Map<String, Set<String>>> clips,
    String packId,
    String folder,
    String fileName,
  ) {
    if (!_languageFolders.contains(folder)) return;
    if (!fileName.endsWith('.mp3')) return;
    final id = fileName.substring(0, fileName.length - 4);
    if (!isValidId(id)) return;
    clips.putIfAbsent(packId, () => {}).putIfAbsent(folder, () => {}).add(id);
  }
}
