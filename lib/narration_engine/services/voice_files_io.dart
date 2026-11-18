import 'dart:io';

import '../models/voice_pack.dart';
import 'voice_import.dart';

/// Unpacks an imported voice into app storage and removes it again.
///
/// The recordings are copied, never linked: once the import finishes, deleting
/// the original zip on the phone changes nothing.
class VoiceFiles {
  const VoiceFiles();

  /// Whether this platform can import a voice at all.
  static const bool supported = true;

  /// Reads [zipPath] and writes its narration into `<directory>/<packId>/`.
  ///
  /// Throws [VoiceImportException] when the archive holds nothing usable; the
  /// caller shows [VoiceImportException.message] and keeps the list untouched.
  Future<VoicePack> install({
    required String zipPath,
    required String directory,
    required String packId,
    required String name,
  }) async {
    final bytes = await File(zipPath).readAsBytes();
    final clips = VoiceImport.clipsFromZip(bytes);

    final root = '$directory/$packId';
    for (final entry in clips.entries) {
      final folder = Directory('$root/${entry.key}');
      await folder.create(recursive: true);
      for (final clip in entry.value.entries) {
        await File(
          '${folder.path}/${clip.key}.mp3',
        ).writeAsBytes(clip.value, flush: true);
      }
    }

    return VoicePack(
      id: packId,
      name: name,
      root: root,
      clips: {
        for (final entry in clips.entries) entry.key: entry.value.keys.toSet(),
      },
    );
  }

  /// Removes an imported voice's recordings. Missing files are not an error.
  Future<void> delete(String root) async {
    if (root.trim().isEmpty) return;
    final directory = Directory(root);
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } on FileSystemException {
      // The row still goes; orphaned files are harmless and invisible.
    }
  }

  /// Drops the temporary copy the file picker left behind.
  Future<void> discardCopy(String zipPath) async {
    try {
      final file = File(zipPath);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // A cache file the system will clean up anyway.
    }
  }
}
