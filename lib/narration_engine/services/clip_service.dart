/// Plays recorded narration lines from the app bundle.
///
/// The recordings are the app's narrator; the text-to-speech engine is only the
/// fallback for a line nobody recorded. Isolated behind an interface for the
/// same reason as [TtsService]: the narration state machine is testable without
/// a device.
///
/// Implementations must never throw: a clip that cannot play reports false.
abstract interface class ClipService {
  /// True once [initialize] confirmed bundled audio can play on this device.
  bool get isAvailable;

  /// Prepares the player. Safe to call more than once.
  Future<void> initialize();

  /// Plays [assetPath] (a `flutter_assets` path such as
  /// `assets/audio/narration/en/night.close_eyes.mp3`) and completes when the
  /// audio ends, is stopped or fails.
  ///
  /// The recording plays at the pace it was made: the speech-speed setting
  /// shapes the fallback voice, not the narrator. Returns false when nothing
  /// played, so the caller can fall back.
  Future<bool> play(String assetPath, {required double volume});

  Future<void> stop();

  Future<void> dispose();
}

/// Used in tests and on platforms without the player: plays nothing and says so.
class SilentClipService implements ClipService {
  const SilentClipService();

  @override
  bool get isAvailable => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> play(String assetPath, {required double volume}) async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
