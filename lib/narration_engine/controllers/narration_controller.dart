import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game_engine/models/composition.dart';
import '../models/narration_instruction.dart';
import '../scripts/night_script.dart';
import '../services/tts_provider.dart';
import '../services/tts_service.dart';

class NarrationState {
  const NarrationState({
    required this.instructions,
    required this.index,
    required this.language,
    required this.isAutoPlaying,
    this.rate = 0.9,
    this.volume = 0.8,
    this.pitch = 0.92,
    this.voiceNotice,
  });

  final List<NarrationInstruction> instructions;
  final int index;
  final NarrationLanguage language;
  final bool isAutoPlaying;
  final double rate;
  final double volume;

  /// Voice depth: below 1.0 is deeper. The default gives the narration a
  /// mature, restrained register.
  final double pitch;

  /// Shown under the panel when the chosen language has no installed voice.
  final String? voiceNotice;

  bool get isEmpty => instructions.isEmpty;
  NarrationInstruction? get current =>
      isEmpty ? null : instructions[index.clamp(0, instructions.length - 1)];
  NarrationInstruction? get nextLine =>
      index + 1 < instructions.length ? instructions[index + 1] : null;

  int get position => isEmpty ? 0 : index + 1;
  int get total => instructions.length;
  double get progress => isEmpty ? 0 : (index + 1) / instructions.length;
  bool get canGoBack => index > 0;
  bool get canGoForward => index + 1 < instructions.length;

  NarrationState copyWith({
    int? index,
    NarrationLanguage? language,
    bool? isAutoPlaying,
    double? rate,
    double? volume,
    double? pitch,
    String? voiceNotice,
    bool clearVoiceNotice = false,
  }) {
    return NarrationState(
      instructions: instructions,
      index: index ?? this.index,
      language: language ?? this.language,
      isAutoPlaying: isAutoPlaying ?? this.isAutoPlaying,
      rate: rate ?? this.rate,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      voiceNotice: clearVoiceNotice ? null : (voiceNotice ?? this.voiceNotice),
    );
  }
}

/// Drives the narration panel and the on-device speech engine.
///
/// Speech is line-at-a-time: each line is spoken to completion, then the panel
/// advances if the MC pressed play. Stopping or moving the line cancels the
/// utterance instead of letting two voices overlap.
class NarrationController extends Notifier<NarrationState> {
  Timer? _timer;

  /// Bumped whenever speech is cancelled, so a late utterance callback cannot
  /// advance a panel the MC already moved.
  int _generation = 0;

  @override
  NarrationState build() {
    ref.onDispose(() {
      _cancelTimer();
      _generation++;
    });
    return NarrationState(
      instructions: const [],
      index: 0,
      language: NarrationLanguage.english,
      isAutoPlaying: false,
    );
  }

  TtsService get _tts => ref.read(ttsServiceProvider);

  /// Prepares the engine. Called once when the narration screen opens.
  Future<void> prepare() async {
    await _tts.initialize();
    await _refreshVoiceNotice();
  }

  void load(Composition composition) {
    _silence();
    state = NarrationState(
      instructions: NightScript.sequenceFor(composition),
      index: 0,
      language: state.language,
      isAutoPlaying: false,
      rate: state.rate,
      volume: state.volume,
      pitch: state.pitch,
    );
  }

  Future<void> next() async {
    if (!state.canGoForward) {
      await pause();
      return;
    }
    _silence();
    state = state.copyWith(index: state.index + 1);
    if (state.isAutoPlaying) await _speakCurrent();
  }

  Future<void> previous() async {
    if (!state.canGoBack) return;
    _silence();
    state = state.copyWith(index: state.index - 1);
    if (state.isAutoPlaying) await _speakCurrent();
  }

  Future<void> replay() async {
    _silence();
    await _speakCurrent();
  }

  Future<void> skipToEnd() async {
    await pause();
    state = state.copyWith(index: state.instructions.length - 1);
  }

  Future<void> toggleAutoPlay() async {
    if (state.isAutoPlaying) {
      await pause();
      return;
    }
    state = state.copyWith(isAutoPlaying: true);
    await _speakCurrent();
  }

  Future<void> pause() async {
    _silence();
    if (state.isAutoPlaying) state = state.copyWith(isAutoPlaying: false);
  }

  Future<void> setLanguage(NarrationLanguage language) async {
    if (state.language == language) return;
    state = state.copyWith(language: language);
    await _refreshVoiceNotice();
    if (state.isAutoPlaying) {
      _silence();
      await _speakCurrent();
    }
  }

  Future<void> setRate(double rate) async {
    state = state.copyWith(rate: rate);
    if (state.isAutoPlaying) {
      _silence();
      await _speakCurrent();
    }
  }

  void setVolume(double volume) {
    state = state.copyWith(volume: volume);
  }

  Future<void> setPitch(double pitch) async {
    state = state.copyWith(pitch: pitch);
    if (state.isAutoPlaying) {
      _silence();
      await _speakCurrent();
    }
  }

  Future<void> _refreshVoiceNotice() async {
    if (!_tts.isAvailable) {
      state = state.copyWith(clearVoiceNotice: true);
      return;
    }
    final locale = _localeFor(state.language);
    final available = await _tts.isLanguageAvailable(locale);
    state = state.copyWith(
      voiceNotice: available ? null : _missingVoiceMessage(state.language),
      clearVoiceNotice: available,
    );
  }

  Future<void> _speakCurrent() async {
    _cancelTimer();
    final generation = ++_generation;
    await _tts.stop();
    final current = state.current;
    if (current == null) return;

    if (!_tts.isAvailable) {
      // No speech engine: keep the panel usable and pace it by estimate.
      if (state.isAutoPlaying) _scheduleAdvance();
      return;
    }

    final locale = _localeFor(state.language);
    final hasVoice = await _tts.isLanguageAvailable(locale);
    if (generation != _generation) return;

    if (!hasVoice) {
      state = state.copyWith(
        voiceNotice: _missingVoiceMessage(state.language),
        isAutoPlaying: false,
      );
      return;
    }

    final spoken = await _tts.speak(
      current.textFor(state.language),
      locale: locale,
      rate: state.rate,
      volume: state.volume,
      pitch: state.pitch,
    );
    if (generation != _generation) return;
    if (!spoken) return;

    if (!state.isAutoPlaying) return;
    if (state.canGoForward) {
      // The Royal Chronicler pauses between instructions; the script decides
      // how long, so the table has time to move the physical cards.
      if (current.pauseAfter > Duration.zero) {
        await Future<void>.delayed(current.pauseAfter);
        if (generation != _generation || !state.isAutoPlaying) return;
      }
      state = state.copyWith(index: state.index + 1);
      await _speakCurrent();
    } else {
      await pause();
    }
  }

  /// Stops speech and invalidates any in-flight utterance callback.
  void _silence() {
    _generation++;
    _cancelTimer();
    unawaited(_tts.stop());
  }

  String _localeFor(NarrationLanguage language) => language.localeCode;

  String _missingVoiceMessage(NarrationLanguage language) =>
      language == NarrationLanguage.filipino
      ? 'This phone has no Filipino voice installed. The Filipino text stays '
            'on screen; add a voice in Android Settings → Text-to-speech, or '
            'switch to English.'
      : 'This phone has no English voice installed. Add one in Android '
            'Settings → Text-to-speech.';

  void _scheduleAdvance() {
    _cancelTimer();
    final current = state.current;
    if (current == null) return;
    _timer = Timer(estimateSpeechDuration(current), () {
      if (!state.isAutoPlaying) return;
      if (state.canGoForward) {
        next();
      } else {
        pause();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

final narrationControllerProvider =
    NotifierProvider<NarrationController, NarrationState>(
      NarrationController.new,
    );
