import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../narration_engine/models/narration_instruction.dart';

/// Settings model. Phase 1 keeps it in memory; Phase 9 persists it in the
/// `Settings` table exactly as declared in the master plan.
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

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void update(AppSettings Function(AppSettings current) transform) {
    state = transform(state);
  }

  void setLanguage(NarrationLanguage language) =>
      state = state.copyWith(defaultLanguage: language);

  void setRate(double rate) =>
      state = state.copyWith(narrationRate: rate.clamp(0.5, 1.5));

  void setPitch(double pitch) =>
      state = state.copyWith(narrationPitch: pitch.clamp(0.7, 1.2));

  void setVolume(double volume) =>
      state = state.copyWith(volume: volume.clamp(0.0, 1.0));

  void setDiscussionSeconds(int seconds) =>
      state = state.copyWith(discussionSeconds: seconds.clamp(60, 1800));

  void setDefaultPlayerCount(int count) =>
      state = state.copyWith(defaultPlayerCount: count.clamp(5, 10));
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

/// Whether destructive actions ask before proceeding.
final settingsConfirmProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider.select((s) => s.confirmations)),
);
