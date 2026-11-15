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

  /// The installed voices that can speak [locale], best first.
  ///
  /// Empty when the engine exposes no voice list; the caller then leaves the
  /// engine to choose, which is what happens before this existed.
  Future<List<TtsVoice>> voices(String locale);

  /// Speaks [text] and completes when the utterance finishes, is stopped or
  /// fails. Returns false when nothing could be spoken.
  ///
  /// [pitch] is the narrator profile: below 1.0 is deeper, above is lighter.
  /// [voiceId] is an exact installed voice from [voices]; null lets the engine
  /// pick the best voice for [locale].
  Future<bool> speak(
    String text, {
    required String locale,
    required double rate,
    required double volume,
    required double pitch,
    String? voiceId,
  });

  Future<void> stop();

  Future<void> dispose();
}

/// One installed voice, as the settings screen lists it.
class TtsVoice {
  const TtsVoice({
    required this.id,
    required this.name,
    required this.locale,
    this.networkRequired = false,
  });

  /// Engine-specific identifier, stable for this installation.
  final String id;

  /// Display name, e.g. `en-gb-x-gba-local`.
  final String name;

  /// BCP-47 tag, e.g. `en-GB`.
  final String locale;

  /// True when the engine needs a network connection for this voice. The
  /// narrator stays offline, so these are listed but not offered.
  final bool networkRequired;

  String get label => '$name · $locale';
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
  Future<List<TtsVoice>> voices(String locale) async => const [];

  @override
  Future<bool> speak(
    String text, {
    required String locale,
    required double rate,
    required double volume,
    required double pitch,
    String? voiceId,
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
