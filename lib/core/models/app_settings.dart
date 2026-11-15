import '../../narration_engine/models/narration_instruction.dart';

/// How the quest leader ("King") is chosen.
///
/// The table's own token still decides who proposes a team; this setting only
/// chooses whether the wheel runs by itself at the start of every round or when
/// the MC asks for it.
enum KingSelectionMode {
  /// The wheel spins at the start of every round, so a new King leads each one.
  automatic('Automatic'),

  /// The wheel spins when the MC opens it; the token keeps its own order.
  manual('Manual');

  const KingSelectionMode(this.label);

  final String label;

  /// Stored name, tolerant of an unknown value from a newer build.
  static KingSelectionMode fromStorage(String? value) {
    for (final mode in KingSelectionMode.values) {
      if (mode.name == value) return mode;
    }
    return KingSelectionMode.manual;
  }
}

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
    this.narratorVoiceId,
    this.narratorExtraDelay = Duration.zero,
    this.keepScreenAwake = true,
    this.confirmations = true,
    this.haptics = true,
    this.soundEffects = true,
    this.discussionSeconds = 300,
    this.defaultPlayerCount = 5,
    this.kingSelectionMode = KingSelectionMode.manual,
    this.teamVoteEnabled = true,
  });

  final NarrationLanguage defaultLanguage;
  final double narrationRate;
  final double narrationPitch;
  final double volume;
  final bool autoAdvance;
  final bool ambientAudio;

  /// Installed TTS voice chosen by the MC; null means "the best available".
  final String? narratorVoiceId;

  /// Extra silence after every spoken narration line, before the panel moves on.
  /// Zero keeps the pace the script itself asks for.
  final Duration narratorExtraDelay;
  final bool keepScreenAwake;
  final bool confirmations;
  final bool haptics;

  /// System tones on confirmed actions, alongside the vibration.
  final bool soundEffects;
  final int discussionSeconds;
  final int defaultPlayerCount;

  /// Whether the wheel draws a new King at the start of every round.
  final KingSelectionMode kingSelectionMode;

  /// Whether the table votes on every proposed team.
  ///
  /// The base game always votes. Some tables play a house rule where the leader
  /// simply names a team, so the vote — and with it the rejection counter — can
  /// be switched off without touching anything else in the match.
  final bool teamVoteEnabled;

  bool get kingsDrawnAutomatically =>
      kingSelectionMode == KingSelectionMode.automatic;

  AppSettings copyWith({
    NarrationLanguage? defaultLanguage,
    double? narrationRate,
    double? narrationPitch,
    double? volume,
    bool? autoAdvance,
    bool? ambientAudio,
    String? narratorVoiceId,
    bool clearNarratorVoice = false,
    Duration? narratorExtraDelay,
    bool? keepScreenAwake,
    bool? confirmations,
    bool? haptics,
    bool? soundEffects,
    int? discussionSeconds,
    int? defaultPlayerCount,
    KingSelectionMode? kingSelectionMode,
    bool? teamVoteEnabled,
  }) {
    return AppSettings(
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      narrationRate: narrationRate ?? this.narrationRate,
      narrationPitch: narrationPitch ?? this.narrationPitch,
      volume: volume ?? this.volume,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      ambientAudio: ambientAudio ?? this.ambientAudio,
      narratorVoiceId: clearNarratorVoice
          ? null
          : narratorVoiceId ?? this.narratorVoiceId,
      narratorExtraDelay: narratorExtraDelay ?? this.narratorExtraDelay,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      confirmations: confirmations ?? this.confirmations,
      haptics: haptics ?? this.haptics,
      soundEffects: soundEffects ?? this.soundEffects,
      discussionSeconds: discussionSeconds ?? this.discussionSeconds,
      defaultPlayerCount: defaultPlayerCount ?? this.defaultPlayerCount,
      kingSelectionMode: kingSelectionMode ?? this.kingSelectionMode,
      teamVoteEnabled: teamVoteEnabled ?? this.teamVoteEnabled,
    );
  }
}
