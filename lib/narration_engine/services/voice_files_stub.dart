import '../models/voice_pack.dart';
import 'voice_import.dart';

/// Stand-in for platforms without `dart:io`.
///
/// A browser tab cannot write a voice into app storage, so the settings screen
/// hides the import action there and this never runs.
class VoiceFiles {
  const VoiceFiles();

  static const bool supported = false;

  Future<VoicePack> install({
    required String zipPath,
    required String directory,
    required String packId,
    required String name,
  }) {
    throw const VoiceImportException(
      'Importing a voice needs the Android app.',
    );
  }

  Future<void> delete(String root) async {}

  Future<void> discardCopy(String zipPath) async {}
}
