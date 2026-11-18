import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game_engine/models/composition.dart';
import '../models/narration_instruction.dart';
import '../models/voice_pack.dart';
import '../scripts/night_script.dart';
import '../services/clip_provider.dart';
import '../services/clip_service.dart';
import '../services/tts_provider.dart';
import '../services/tts_service.dart';
import 'voice_packs_controller.dart';

class NarrationState {
  const NarrationState({
    required this.instructions,
    required this.index,
    required this.language,
    required this.isAutoPlaying,
    this.rate = 0.9,
    this.volume = 0.8,
    this.pitch = 0.92,
    this.voiceId,
    this.voicePackId,
    this.extraDelay = Duration.zero,
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

  /// Exact installed voice chosen in settings; null means the best for the
  /// language. Kept here so a mid-match language switch re-picks a voice.
  final String? voiceId;

  /// Recorded narrator chosen in settings; null means the shipped recordings.
  ///
  /// It lives in the panel state as well as in settings so a voice switched
  /// between two matches takes effect on the next night, never mid-line.
  final String? voicePackId;

  /// Silence the MC asked for after every line, on top of the script's own
  /// beat. It starts only once the line has finished speaking.
  final Duration extraDelay;

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
    String? voiceId,
    bool clearVoice = false,
    String? voicePackId,
    bool clearVoicePack = false,
    Duration? extraDelay,
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
      voiceId: clearVoice ? null : (voiceId ?? this.voiceId),
      voicePackId: clearVoicePack
          ? null
          : (voicePackId ?? this.voicePackId),
      extraDelay: extraDelay ?? this.extraDelay,
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

  /// The wait between two lines. Held so a pause, a skip or a restart can end it
  /// early instead of leaving a timer to fire into a panel the MC has moved.
  Timer? _waitTimer;
  Completer<void>? _wait;

  /// Bumped whenever speech is cancelled, so a late utterance callback cannot
  /// advance a panel the MC already moved.
  int _generation = 0;

  @override
  NarrationState build() {
    ref.onDispose(() {
      _cancelTimer();
      _cancelWait();
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
  ClipService get _clips => ref.read(clipServiceProvider);

  /// The recorded voice this night is read in.
  VoicePack get _pack => ref.read(voicePacksProvider).active(state.voicePackId);

  /// Prepares the recorded narration and the speech engine. Called once when
  /// the narration screen opens.
  Future<void> prepare() async {
    await ref.read(voicePacksProvider.notifier).refresh();
    await _clips.initialize();
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
      voiceId: state.voiceId,
      voicePackId: state.voicePackId,
      extraDelay: state.extraDelay,
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

  /// Extra silence after every line. It applies from the next line on: a line
  /// that is already speaking is never interrupted by a settings change.
  void setExtraDelay(Duration delay) {
    final capped = Duration(
      milliseconds: delay.inMilliseconds.clamp(0, 20000),
    );
    if (state.extraDelay == capped) return;
    state = state.copyWith(extraDelay: capped);
  }

  Future<void> setPitch(double pitch) async {
    state = state.copyWith(pitch: pitch);
    if (state.isAutoPlaying) {
      _silence();
      await _speakCurrent();
    }
  }

  /// Chooses an exact installed voice, or null for "the best available".
  Future<void> setVoice(String? voiceId) async {
    state = voiceId == null
        ? state.copyWith(clearVoice: true)
        : state.copyWith(voiceId: voiceId);
    if (state.isAutoPlaying) {
      _silence();
      await _speakCurrent();
    }
  }

  /// Chooses the recorded narrator, or null for the recordings in the app.
  Future<void> setVoicePack(String? voicePackId) async {
    if (state.voicePackId == voicePackId) return;
    state = voicePackId == null
        ? state.copyWith(clearVoicePack: true)
        : state.copyWith(voicePackId: voicePackId);
    await _refreshVoiceNotice();
    if (state.isAutoPlaying) {
      _silence();
      await _speakCurrent();
    }
  }

  Future<void> _refreshVoiceNotice() async {
    // A recorded line needs no installed voice, so there is nothing to warn
    // about while the recordings cover the night.
    if (_hasClipFor(state.current)) {
      state = state.copyWith(clearVoiceNotice: true);
      return;
    }
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
    _cancelWait();
    final generation = ++_generation;
    await _clips.stop();
    await _tts.stop();
    final current = state.current;
    if (current == null) return;

    // The recordings are the narrator. The speech engine only covers a line
    // this voice did not record, or a clip the player could not open.
    final clip = _pack.pathFor(current.id, state.language);
    if (clip != null && _clips.isAvailable) {
      final played = await _clips.play(clip, volume: state.volume);
      if (generation != _generation) return;
      if (played) {
        await _advanceAfter(current, generation);
        return;
      }
    }

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
      voiceId: state.voiceId,
    );
    if (generation != _generation) return;
    if (!spoken) return;

    await _advanceAfter(current, generation);
  }

  /// The beat between two lines, once one has finished playing.
  ///
  /// Speech has finished — only now does the wait begin: the script's own beat
  /// plus the MC's extra delay. The table gets the time it asked for to move its
  /// physical cards before the next line appears.
  Future<void> _advanceAfter(
    NarrationInstruction current,
    int generation,
  ) async {
    if (!state.isAutoPlaying) return;
    if (state.canGoForward) {
      final wait = current.pauseAfter + state.extraDelay;
      if (wait > Duration.zero) {
        await _waitFor(wait);
        if (generation != _generation || !state.isAutoPlaying) return;
      }
      state = state.copyWith(index: state.index + 1);
      await _speakCurrent();
    } else {
      await pause();
    }
  }

  /// Whether [line] plays from this voice's recordings.
  bool _hasClipFor(NarrationInstruction? line) =>
      line != null &&
      _clips.isAvailable &&
      _pack.pathFor(line.id, state.language) != null;

  /// Stops speech and invalidates any in-flight utterance callback.
  void _silence() {
    _generation++;
    _cancelTimer();
    _cancelWait();
    unawaited(_clips.stop());
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
    _timer = Timer(
      estimateSpeechDuration(current) + state.extraDelay,
      () {
        if (!state.isAutoPlaying) return;
        if (state.canGoForward) {
          next();
        } else {
          pause();
        }
      },
    );
  }

  /// Waits [duration] unless something cancels it first.
  Future<void> _waitFor(Duration duration) {
    _cancelWait();
    if (duration <= Duration.zero) return Future<void>.value();
    final completer = Completer<void>();
    _wait = completer;
    _waitTimer = Timer(duration, () {
      _waitTimer = null;
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  void _cancelWait() {
    _waitTimer?.cancel();
    _waitTimer = null;
    final pending = _wait;
    _wait = null;
    if (pending != null && !pending.isCompleted) pending.complete();
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
