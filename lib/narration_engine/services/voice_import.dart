import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../services/voice_pack_catalogue.dart';

/// A reconstruction of one narrator voice from a zip.
///
/// A pack is fourteen or so MP3s, so "import a voice" means importing a folder
/// of files, not a single one. This reads whatever the MC hands the app and
/// keeps only what it can recognise: `<en|fil>/<id>.mp3`, however deeply the zip
/// nests them. Everything else — artwork, notes, the macOS resource fork — is
/// ignored rather than rejected.
abstract final class VoiceImport {
  /// The only folders a pack may have: they mirror the shipped recordings.
  static const languageFolders = {'en', 'fil'};

  /// A sanity limit: a narrator pack is a few megabytes, not an archive dump.
  static const maxEntries = 800;

  /// Reads a zip into `language → line id → MP3 bytes`.
  ///
  /// Throws [VoiceImportException] with something the MC can act on when the
  /// file is not a zip or holds no narration at all.
  static Map<String, Map<String, Uint8List>> clipsFromZip(List<int> bytes) {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: false);
    } catch (_) {
      throw const VoiceImportException(
        'That file could not be opened as a zip. Send the voice as a .zip '
        'containing an en/ folder, a fil/ folder, or both.',
      );
    }

    if (archive.files.length > maxEntries) {
      throw const VoiceImportException(
        'That zip holds too many files to be a voice pack.',
      );
    }

    final clips = <String, Map<String, Uint8List>>{};
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final path = file.name.replaceAll('\\', '/');
      final segments = path
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList();
      if (segments.isEmpty) continue;
      if (segments.any((segment) => segment == '..' || segment == '__MACOSX')) {
        continue;
      }
      final fileName = segments.last;
      if (!fileName.toLowerCase().endsWith('.mp3')) continue;

      final id = fileName.substring(0, fileName.length - 4);
      if (!VoicePackCatalogue.isValidId(id)) continue;

      final folder = _languageFor(segments);
      if (folder == null) continue;

      final data = _bytesOf(file);
      if (data.isEmpty) continue;
      clips.putIfAbsent(folder, () => {})[id] = data;
    }

    if (clips.isEmpty) {
      throw const VoiceImportException(
        'No narration files were found in that zip. Name each recording after '
        'the line it reads — night.close_eyes.mp3, night.evil.wake.mp3 — and '
        'put them in an en/ or fil/ folder.',
      );
    }
    return clips;
  }

  /// A folder name for a zip made from a display name: "Voice of Dahlia" →
  /// `voice-of-dahlia`. Folders are lowercase so they never look like a path.
  static String slugForName(String name) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) return 'voice';
    return slug.substring(0, math.min(slug.length, 40));
  }

  /// [base], or the first free `base-2`, `base-3`… so importing the same name
  /// twice creates a second voice instead of overwriting the first.
  static String uniqueId(String base, Iterable<String> taken) {
    final used = taken.toSet();
    if (!used.contains(base)) return base;
    for (var suffix = 2; suffix < 1000; suffix++) {
      final candidate = '$base-$suffix';
      if (!used.contains(candidate)) return candidate;
    }
    return '$base-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// The language folder a file belongs to.
  ///
  /// `fil/night.end.mp3` and `Voice of Dahlia/en/night.end.mp3` both work. A zip
  /// whose MP3s sit at the root — or in a single wrapper folder — is read as
  /// English, which is the shipped fallback language.
  static String? _languageFor(List<String> segments) {
    if (segments.length >= 2) {
      final parent = segments[segments.length - 2];
      if (languageFolders.contains(parent)) return parent;
    }
    if (segments.length <= 2) return 'en';
    return null;
  }

  static Uint8List _bytesOf(ArchiveFile file) {
    final content = file.content;
    if (content is Uint8List) return content;
    if (content is List<int>) return Uint8List.fromList(content);
    return Uint8List(0);
  }
}

/// Why a voice pack could not be imported, in words the MC can act on.
class VoiceImportException implements Exception {
  const VoiceImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
