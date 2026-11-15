import '../models/narration_instruction.dart';

/// The speech layer, isolated behind an interface so the narration state
/// machine can be tested without a device (master plan §6.3).
///
/// Implementations must be safe to call repeatedly and must never throw: a
/// missing voice is reported through [isAvailable], not an exception.
abstract interface class TtsService {
  /// True once the platform engine answered and can speak.
  bool get isAvailable;

  /// MC-readable explanation when [isAvailable] is false.
  String? get unavailableReason;

  /// Prepares the engine. Safe to call more than once.
  Future<void> initialize();

  /// Whether [locale] (a BCP-47 tag such as `fil-PH`) has a voice installed.
  Future<bool> isLanguageAvailable(String locale);

  /// Speaks [text] and completes when the utterance finishes, is stopped or
  /// fails. Returns false when nothing could be spoken.
  ///
  /// [pitch] is the narrator profile: below 1.0 is deeper, above is lighter.
  Future<bool> speak(
    String text, {
    required String locale,
    required double rate,
    required double volume,
    required double pitch,
  });

  Future<void> stop();

  Future<void> dispose();
}

/// Used when no platform engine exists, and in tests. Speaks nothing and
/// explains that plainly instead of pretending.
class SilentTtsService implements TtsService {
  const SilentTtsService();

  @override
  bool get isAvailable => false;

  @override
  String get unavailableReason =>
      'Voice narration is not connected yet — read the lines aloud for now.';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isLanguageAvailable(String locale) async => false;

  @override
  Future<bool> speak(
    String text, {
    required String locale,
    required double rate,
    required double volume,
    required double pitch,
  }) async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

/// Estimated spoken length, used by auto-advance when the device cannot speak.
Duration estimateSpeechDuration(NarrationInstruction instruction) {
  final words = instruction.english.split(RegExp(r'\s+')).length;
  return Duration(milliseconds: 1400 + words * 320) + instruction.pauseAfter;
}
