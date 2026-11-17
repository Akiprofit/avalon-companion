import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/settings_controller.dart';

/// Confirmation at the table without looking at the screen.
///
/// The phone lies on the table between hands, so a short vibration is often the
/// only proof that a tap registered. Everything here is optional and driven by
/// the MC's settings: with both switches off, [SilentFeedback] does nothing.
abstract interface class Feedback {
  /// A confirmed action: a dialog accepted, a count recorded.
  void tap();

  /// A card picked up for selection: firmer than [tap], so a long press that
  /// the MC could not watch still feels acknowledged.
  void select();

  /// The match moved to another phase.
  void phaseChange();

  /// Something was refused, or a count is out of range.
  void warning();

  /// A countdown reached zero: two short heavy taps, distinct from [warning].
  void alarm();
}

/// Real haptics and system tones.
class PlatformFeedback implements Feedback {
  const PlatformFeedback({this.withSound = true});

  /// The MC's sound-effects preference. Vibration can stay on without it.
  final bool withSound;

  @override
  void tap() {
    unawaited(HapticFeedback.selectionClick());
    if (withSound) unawaited(SystemSound.play(SystemSoundType.click));
  }

  @override
  void select() {
    unawaited(HapticFeedback.mediumImpact());
    if (withSound) unawaited(SystemSound.play(SystemSoundType.click));
  }

  @override
  void phaseChange() {
    unawaited(HapticFeedback.mediumImpact());
    if (withSound) unawaited(SystemSound.play(SystemSoundType.click));
  }

  @override
  void warning() => unawaited(HapticFeedback.heavyImpact());

  @override
  void alarm() {
    unawaited(HapticFeedback.heavyImpact());
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 180),
        HapticFeedback.heavyImpact,
      ),
    );
  }
}

/// Haptics and tones off.
class SilentFeedback implements Feedback {
  const SilentFeedback();

  @override
  void tap() {}

  @override
  void select() {}

  @override
  void phaseChange() {}

  @override
  void warning() {}

  @override
  void alarm() {}
}

/// Feedback for the current preferences.
///
/// Vibration is the "Haptic feedback" switch; tones are the "Sound effects"
/// switch. Either one alone keeps the other working.
final feedbackProvider = Provider<Feedback>((ref) {
  final prefs = ref.watch(
    settingsProvider.select((s) => (haptics: s.haptics, sound: s.soundEffects)),
  );
  if (!prefs.haptics) return const SilentFeedback();
  return PlatformFeedback(withSound: prefs.sound);
});
