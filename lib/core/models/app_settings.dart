import '../../narration_engine/models/narration_instruction.dart';

/// User preferences. Phase 9 persists these in the `Settings` table exactly as
/// declared in the master plan (PART 8).
///
/// Lives in `core/models` rather than in the settings feature so the database
/// layer can map it without importing a screen-facing controller.
class AppSettings {
  const AppSettings({
    this.defaultLanguage = NarrationLanguage.english,
    this.narrationRate = 0.9,
    this.narrationPitch = 0.92,
    this.volume = 0.8,
    this.autoAdvance = false,
    this.ambientAudio = false,
    this.keepScreenAwake = true,
    this.confirmations = true,
    this.haptics = true,
    this.discussionSeconds = 300,
    this.defaultPlayerCount = 5,
  });

  final NarrationLanguage defaultLanguage;
  final double narrationRate;
  final double narrationPitch;
  final double volume;
  final bool autoAdvance;
  final bool ambientAudio;
  final bool keepScreenAwake;
  final bool confirmations;
  final bool haptics;
  final int discussionSeconds;
  final int defaultPlayerCount;

  AppSettings copyWith({
    NarrationLanguage? defaultLanguage,
    double? narrationRate,
    double? narrationPitch,
    double? volume,
    bool? autoAdvance,
    bool? ambientAudio,
    bool? keepScreenAwake,
    bool? confirmations,
    bool? haptics,
    int? discussionSeconds,
    int? defaultPlayerCount,
  }) {
    return AppSettings(
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      narrationRate: narrationRate ?? this.narrationRate,
      narrationPitch: narrationPitch ?? this.narrationPitch,
      volume: volume ?? this.volume,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      ambientAudio: ambientAudio ?? this.ambientAudio,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      confirmations: confirmations ?? this.confirmations,
      haptics: haptics ?? this.haptics,
      discussionSeconds: discussionSeconds ?? this.discussionSeconds,
      defaultPlayerCount: defaultPlayerCount ?? this.defaultPlayerCount,
    );
  }
}
