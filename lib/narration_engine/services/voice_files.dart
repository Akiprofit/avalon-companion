/// Filesystem work for narrator voice packs, split out so the web build still
/// compiles: `dart:io` is only imported on platforms that have it.
library;

export 'voice_files_stub.dart' if (dart.library.io) 'voice_files_io.dart';
