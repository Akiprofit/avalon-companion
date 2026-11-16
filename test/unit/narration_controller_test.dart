import 'dart:async';

import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:avalon_companion/narration_engine/controllers/narration_controller.dart';
import 'package:avalon_companion/narration_engine/models/narration_instruction.dart';
import 'package:avalon_companion/narration_engine/services/clip_provider.dart';
import 'package:avalon_companion/narration_engine/services/clip_service.dart';
import 'package:avalon_companion/narration_engine/services/tts_provider.dart';
import 'package:avalon_companion/narration_engine/services/tts_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for the platform engine. Speech only completes when the test says
/// so, which is how a real utterance behaves.
class FakeTtsService implements TtsService {
  FakeTtsService({this.available = true, Set<String>? languages})
    : languages = languages ?? {AndroidLocales.english};

  final bool available;
  final Set<String> languages;

  final List<String> spoken = [];
  String? lastLocale;
  double? lastRate;
  double? lastVolume;
  double? lastPitch;
  String? lastVoiceId;
  int stopCount = 0;
  bool initialised = false;

  Completer<bool>? _pending;

  @override
  bool get isAvailable => available;

  @override
  String? get unavailableReason => available ? null : 'No engine.';

  @override
  Future<void> initialize() async {
    initialised = true;
  }

  @override
  Future<bool> isLanguageAvailable(String locale) async =>
      languages.contains(locale);

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
  }) {
    spoken.add(text);
    lastLocale = locale;
    lastRate = rate;
    lastVolume = volume;
    lastPitch = pitch;
    lastVoiceId = voiceId;
    final completion = Completer<bool>();
    _pending = completion;
    return completion.future;
  }

  /// Ends the utterance the way the platform callback would.
  void completeSpeech({bool spoken = true}) {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(spoken);
  }

  @override
  Future<void> stop() async {
    stopCount++;
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(false);
  }

  @override
  Future<void> dispose() async {}
}

/// A stand-in for the recorded narrator. Playback ends when the test says so,
/// the way a real clip ends when the file reaches its last frame.
class FakeClipService implements ClipService {
  FakeClipService({this.available = true, this.plays = true});

  final bool available;

  /// False makes every play attempt fail, which is how a missing or unreadable
  /// file behaves.
  final bool plays;

  final List<String> played = [];
  double? lastVolume;
  int stopCount = 0;

  Completer<bool>? _pending;

  @override
  bool get isAvailable => available;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> play(String assetPath, {required double volume}) {
    played.add(assetPath);
    lastVolume = volume;
    if (!plays) return Future<bool>.value(false);
    final completion = Completer<bool>();
    _pending = completion;
    return completion.future;
  }

  /// Ends the clip the way the player callback would.
  void completeClip() {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(true);
  }

  @override
  Future<void> stop() async {
    stopCount++;
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(false);
  }

  @override
  Future<void> dispose() async {}
}

/// Only the tags the fake needs; the production tags live in
/// `AndroidTtsService`.
abstract final class AndroidLocales {
  static const english = 'en-GB';
  static const filipino = 'fil-PH';
}

Composition compositionFor(int playerCount) {
  final defaults = AvalonTables.defaultComposition(playerCount);
  final counts = <Character, int>{};
  for (final character in Character.values) {
    final value = defaults[character.label];
    if (value != null && value > 0) counts[character] = value;
  }
  return Composition(playerCount: playerCount, counts: counts);
}

/// Lets every pending microtask in the controller run.
Future<void> settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeTtsService tts;
  late FakeClipService clips;
  late ProviderContainer container;

  NarrationController controller() =>
      container.read(narrationControllerProvider.notifier);
  NarrationState state() => container.read(narrationControllerProvider);

  void setUpController({
    bool available = true,
    Set<String>? languages,
    FakeClipService? recorded,
  }) {
    tts = FakeTtsService(available: available, languages: languages);
    // Recorded narration is off unless a test asks for it, so these tests keep
    // describing the fallback path exactly as before.
    clips = recorded ?? FakeClipService(available: false);
    container = ProviderContainer(
      overrides: [
        ttsServiceProvider.overrideWithValue(tts),
        clipServiceProvider.overrideWithValue(clips),
      ],
    );
    addTearDown(container.dispose);
    controller().load(compositionFor(5));
  }

  List<String> sequenceIds() =>
      NightSequenceIds.idsOf(state().instructions);

  /// Ends the current utterance and waits out the narrator's deliberate pause,
  /// which is longer than [settle] can cover.
  Future<void> finishLine() async {
    tts.completeSpeech();
    await settle();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await settle();
  }

  test('playing speaks the current line, not before', () async {
    setUpController();
    await settle();
    expect(tts.spoken, isEmpty);

    unawaited(controller().toggleAutoPlay());
    await settle();

    expect(tts.spoken, hasLength(1));
    expect(tts.spoken.single, state().current!.english);
    expect(state().isAutoPlaying, isTrue);
    expect(state().index, 0, reason: 'the panel waits for the line to finish');
  });

  test('speech completion advances the panel', () async {
    setUpController();
    await settle();

    unawaited(controller().toggleAutoPlay());
    await settle();
    final firstText = tts.spoken.single;

    await finishLine();

    expect(state().index, 1);
    expect(tts.spoken, hasLength(2));
    expect(tts.spoken.last, state().current!.english);
    expect(tts.spoken.last, isNot(firstText));

    unawaited(controller().pause());
    await settle();
  });

  test('pause stops speech and leaves the panel where it is', () async {
    setUpController();
    await settle();

    unawaited(controller().toggleAutoPlay());
    await settle();
    final index = state().index;
    final stopsBefore = tts.stopCount;

    unawaited(controller().pause());
    await settle();

    expect(state().isAutoPlaying, isFalse);
    expect(state().index, index);
    expect(tts.stopCount, greaterThan(stopsBefore));
  });

  test('the rate and volume from settings reach the engine', () async {
    setUpController();
    await settle();

    controller().setVolume(0.35);
    unawaited(controller().setRate(1.2));
    await settle();
    unawaited(controller().toggleAutoPlay());
    await settle();

    expect(tts.lastRate, 1.2);
    expect(tts.lastVolume, 0.35);

    unawaited(controller().pause());
    await settle();
  });

  test('moving the line while playing cancels the old utterance', () async {
    setUpController();
    await settle();

    unawaited(controller().toggleAutoPlay());
    await settle();
    final firstText = tts.spoken.single;

    unawaited(controller().next());
    await settle();

    expect(state().index, 1);
    expect(tts.spoken.last, state().current!.english);
    expect(tts.spoken.last, isNot(firstText));
    expect(state().isAutoPlaying, isTrue);

    // The engine stops the line that was cut off, so its callback resolves as
    // "not spoken" and cannot advance the panel on its own.
    tts.completeSpeech();
    await settle();
    expect(state().index, 1, reason: 'the cut-off line cannot advance');

    await finishLine();
    expect(state().index, 2, reason: 'exactly one advance per finished line');

    unawaited(controller().pause());
    await settle();
  });

  test('next and previous stay silent while paused', () async {
    setUpController();
    await settle();

    unawaited(controller().next());
    await settle();
    expect(state().index, 1);
    expect(tts.spoken, isEmpty);

    unawaited(controller().previous());
    await settle();
    expect(state().index, 0);
    expect(tts.spoken, isEmpty);
  });

  test('replay always speaks, even when paused', () async {
    setUpController();
    await settle();

    unawaited(controller().replay());
    await settle();

    expect(tts.spoken, [state().current!.english]);
    expect(state().isAutoPlaying, isFalse);

    tts.completeSpeech();
    await settle();
    expect(state().index, 0, reason: 'replay must not advance');
  });

  test('a missing Filipino voice explains itself and stops autoplay', () async {
    setUpController(languages: {AndroidLocales.english});
    await settle();

    unawaited(controller().setLanguage(NarrationLanguage.filipino));
    await settle();
    expect(state().voiceNotice, contains('Filipino voice'));

    unawaited(controller().toggleAutoPlay());
    await settle();

    expect(tts.spoken, isEmpty);
    expect(state().isAutoPlaying, isFalse);
    expect(state().voiceNotice, contains('Filipino voice'));
  });

  test('switching back to English clears the notice', () async {
    setUpController(languages: {AndroidLocales.english});
    await settle();

    unawaited(controller().setLanguage(NarrationLanguage.filipino));
    await settle();
    expect(state().voiceNotice, isNotNull);

    unawaited(controller().setLanguage(NarrationLanguage.english));
    await settle();
    expect(state().voiceNotice, isNull);
  });

  test('the Royal Chronicler profile reaches the engine', () async {
    setUpController();
    await settle();

    unawaited(controller().replay());
    await settle();

    expect(tts.lastLocale, AndroidLocales.english,
        reason: 'British English is the narrator identity');
    expect(tts.lastPitch, closeTo(0.92, 0.001),
        reason: 'a slightly deep pitch reads as a mature storyteller');
    expect(tts.lastRate, closeTo(0.9, 0.001));

    tts.completeSpeech();
    await settle();
  });

  test('the voice depth from settings reaches the engine', () async {
    setUpController();
    await settle();

    unawaited(controller().setPitch(0.8));
    await settle();
    unawaited(controller().replay());
    await settle();

    expect(tts.lastPitch, closeTo(0.8, 0.001));

    tts.completeSpeech();
    await settle();
  });

  test('the narrator pauses between lines before advancing', () async {
    setUpController();
    await settle();

    unawaited(controller().toggleAutoPlay());
    await settle();
    final firstText = tts.spoken.single;

    tts.completeSpeech();
    await settle();

    // The first line asks for a deliberate pause; the panel must not jump the
    // moment the voice stops, or the MC loses the beat between instructions.
    expect(state().index, 0);
    expect(tts.spoken, [firstText]);

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await settle();

    expect(state().index, 1);
    expect(tts.spoken, hasLength(2));
    expect(tts.spoken.last, state().current!.english);

    unawaited(controller().pause());
    await settle();
  });

  test('a Filipino voice is used when the phone has one', () async {
    setUpController(languages: {AndroidLocales.english, AndroidLocales.filipino});
    await settle();

    unawaited(controller().setLanguage(NarrationLanguage.filipino));
    await settle();
    expect(state().voiceNotice, isNull);

    unawaited(controller().replay());
    await settle();

    expect(tts.lastLocale, AndroidLocales.filipino);
    expect(tts.spoken.single, state().current!.filipino);

    tts.completeSpeech();
    await settle();
  });

  test('without an engine the panel still works and stays silent', () async {
    setUpController(available: false);
    await settle();

    await expectLater(controller().prepare(), completes);
    unawaited(controller().next());
    await settle();
    expect(state().index, 1);

    unawaited(controller().replay());
    await settle();
    expect(tts.spoken, isEmpty);
    expect(state().voiceNotice, isNull,
        reason: 'a silent engine is not a missing language voice');
  });

  test('skipToEnd pauses and jumps to the last line', () async {
    setUpController();
    await settle();

    unawaited(controller().toggleAutoPlay());
    await settle();

    unawaited(controller().skipToEnd());
    await settle();

    expect(state().isAutoPlaying, isFalse);
    expect(state().index, state().total - 1);
    expect(state().canGoForward, isFalse);
    expect(state().current!.id, sequenceIds().last);
  });

  test('the extra delay starts only after the line has finished', () async {
    setUpController();
    controller().setExtraDelay(const Duration(seconds: 2));
    await settle();

    unawaited(controller().toggleAutoPlay());
    await settle();
    expect(tts.spoken, hasLength(1));

    tts.completeSpeech();
    await settle();

    // Speech is over, but the script's beat plus the extra delay still run: the
    // table gets its time to move the physical cards.
    expect(state().index, 0);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await settle();
    expect(state().index, 0, reason: 'the extra delay is still counting');
    expect(tts.spoken, hasLength(1), reason: 'nothing is spoken during the wait');

    await Future<void>.delayed(const Duration(milliseconds: 2200));
    await settle();
    expect(state().index, 1);
    expect(tts.spoken, hasLength(2));

    unawaited(controller().pause());
    await settle();
  });

  test('skipping during the extra delay leaves no timer behind', () async {
    setUpController();
    controller().setExtraDelay(const Duration(seconds: 2));
    await settle();

    unawaited(controller().toggleAutoPlay());
    await settle();
    tts.completeSpeech();
    await settle();

    unawaited(controller().skipToEnd());
    await settle();
    final index = state().index;
    expect(state().isAutoPlaying, isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 3000));
    await settle();

    expect(state().index, index, reason: 'a cancelled delay cannot advance');
    expect(tts.spoken, hasLength(1), reason: 'and cannot speak again');
  });

  test('restarting a line mid-delay advances exactly once', () async {
    setUpController();
    controller().setExtraDelay(const Duration(seconds: 1));
    await settle();

    unawaited(controller().toggleAutoPlay());
    await settle();
    tts.completeSpeech();
    await settle();

    // The MC repeats the line before the panel has moved on.
    unawaited(controller().replay());
    await settle();
    expect(state().index, 0);
    tts.completeSpeech();
    await settle();

    await Future<void>.delayed(const Duration(milliseconds: 2400));
    await settle();

    expect(state().index, 1, reason: 'exactly one advance, not two');

    unawaited(controller().pause());
    await settle();
  });

  test('the delay is capped and carried into a reload', () {
    setUpController();

    controller().setExtraDelay(const Duration(minutes: 5));
    expect(state().extraDelay, const Duration(seconds: 20));

    controller().setExtraDelay(const Duration(seconds: 3));
    controller().load(compositionFor(5));
    expect(state().extraDelay, const Duration(seconds: 3));
    expect(state().index, 0);
  });

  test('the night sequence depends on the composition only', () async {
    setUpController();
    await settle();

    final fivePlayer = sequenceIds();
    controller().load(compositionFor(5));
    expect(sequenceIds(), fivePlayer);

    // The controller is told which characters are in play, never who has them:
    // there is no player argument anywhere in this API.
    expect(state().total, greaterThan(0));
    expect(state().total, fivePlayer.length);
  });

  group('recorded narrator', () {
    test('plays the clip instead of the speech engine', () async {
      setUpController(recorded: FakeClipService());
      await controller().prepare();
      await settle();

      unawaited(controller().replay());
      await settle();

      expect(clips.played, ['assets/audio/narration/en/night.close_eyes.mp3']);
      expect(tts.spoken, isEmpty, reason: 'the engine is the fallback only');

      clips.completeClip();
      await settle();
    });

    test('plays the Filipino recording for the Filipino text', () async {
      setUpController(recorded: FakeClipService());
      await controller().prepare();
      await settle();

      unawaited(controller().setLanguage(NarrationLanguage.filipino));
      await settle();
      unawaited(controller().replay());
      await settle();

      expect(state().language, NarrationLanguage.filipino);
      expect(clips.played.single, endsWith('/fil/night.close_eyes.mp3'));
      expect(tts.spoken, isEmpty);

      clips.completeClip();
      await settle();
    });

    test('the volume from settings reaches the player, not the pace', () async {
      setUpController(recorded: FakeClipService());
      await controller().prepare();
      await settle();

      controller().setVolume(0.35);
      unawaited(controller().setRate(1.2));
      await settle();
      unawaited(controller().replay());
      await settle();

      expect(clips.lastVolume, 0.35);
      expect(
        state().rate,
        1.2,
        reason: 'the speech setting is kept for the fallback voice',
      );
      expect(
        tts.spoken,
        isEmpty,
        reason: 'the recording still plays at its own pace',
      );

      clips.completeClip();
      await settle();
    });

    test('a finished recording advances the panel like speech', () async {
      setUpController(recorded: FakeClipService());
      await controller().prepare();
      await settle();

      unawaited(controller().toggleAutoPlay());
      await settle();
      expect(state().index, 0, reason: 'the panel waits for the clip');
      expect(clips.played, hasLength(1));

      clips.completeClip();
      await settle();
      expect(state().index, 0, reason: 'the script beat still runs');

      await Future<void>.delayed(const Duration(milliseconds: 1500));
      await settle();

      expect(state().index, 1);
      expect(clips.played, hasLength(2));
      expect(clips.played.last, endsWith('/en/night.evil.wake.mp3'));

      unawaited(controller().pause());
      await settle();
    });

    test('a clip that cannot play falls back to the engine', () async {
      setUpController(recorded: FakeClipService(plays: false));
      await controller().prepare();
      await settle();

      unawaited(controller().replay());
      await settle();

      expect(clips.played, hasLength(1), reason: 'the recording was tried');
      expect(tts.spoken.single, state().current!.english);

      tts.completeSpeech();
      await settle();
    });

    test('a recorded line needs no installed voice', () async {
      setUpController(languages: const {}, recorded: FakeClipService());
      await controller().prepare();
      await settle();
      expect(
        state().voiceNotice,
        isNull,
        reason: 'the recordings cover the line, so there is no warning',
      );

      unawaited(controller().toggleAutoPlay());
      await settle();

      expect(clips.played, hasLength(1));
      expect(tts.spoken, isEmpty);
      expect(state().isAutoPlaying, isTrue);

      clips.completeClip();
      await settle();
      unawaited(controller().pause());
      await settle();
    });
  });
}

/// Test-side helper so the assertions can name the first and last line.
abstract final class NightSequenceIds {
  static List<String> idsOf(List<NarrationInstruction> instructions) =>
      instructions.map((i) => i.id).toList();
}
