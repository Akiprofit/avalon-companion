import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_files.dart';
import 'voice_import_channel.dart';

/// The platform picker and the folder imported voices live in.
final voiceImportChannelProvider = Provider<VoiceImportChannel>(
  (ref) => VoiceImportChannel(),
);

/// Unpacking and deleting voice files. Overridden in tests so nothing touches
/// the disk.
final voiceFilesProvider = Provider<VoiceFiles>((ref) => const VoiceFiles());
