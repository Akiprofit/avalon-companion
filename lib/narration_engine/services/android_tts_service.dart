import 'dart:async';

import 'package:flutter/services.dart';

import 'tts_service.dart';

/// Talks to the Android text-to-speech engine over the channel implemented in
/// `MainActivity.kt`. Everything is synthesised on the device; no text leaves it.
class AndroidTtsService implements TtsService {
  AndroidTtsService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.avalon.companion/tts';

  /// The Royal Chronicler: British English, the closest installed voice to a
  /// mature royal historian. Android falls back to another English voice when
  /// no en-GB voice is installed, so narration never goes silent over an
  /// accent.
  static const englishLocale = 'en-GB';
  static const filipinoLocale = 'fil-PH';

  final MethodChannel _channel;

  bool _isAvailable = false;
  String? _unavailableReason;
  bool _initialised = false;
  Completer<void>? _utterance;

  @override
  bool get isAvailable => _isAvailable;

  @override
  String? get unavailableReason => _unavailableReason;

  @override
  Future<void> initialize() async {
    if (_initialised) return;
    _initialised = true;

    _channel.setMethodCallHandler(_handlePlatformCall);
    try {
      final ready = await _channel.invokeMethod<bool>('init') ?? false;
      _isAvailable = ready;
      if (!ready) {
        _unavailableReason =
            'This phone has no text-to-speech engine available, so the '
            'narration is silent. Read the lines aloud.';
      }
    } on PlatformException catch (error) {
      _isAvailable = false;
      _unavailableReason =
          'Text-to-speech could not start (${error.code}). Read the lines '
          'aloud.';
    } on MissingPluginException {
      _isAvailable = false;
      _unavailableReason =
          'Text-to-speech is not available in this build. Read the lines '
          'aloud.';
    }
  }

  Future<dynamic> _handlePlatformCall(MethodCall call) async {
    if (call.method == 'onDone' ||
        call.method == 'onStop' ||
        call.method == 'onError') {
      _finishUtterance();
    }
    return null;
  }

  @override
  Future<bool> isLanguageAvailable(String locale) async {
    await initialize();
    if (!_isAvailable) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'isLanguageAvailable',
            {'locale': locale},
          ) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> speak(
    String text, {
    required String locale,
    required double rate,
    required double volume,
    required double pitch,
  }) async {
    await initialize();
    if (!_isAvailable) return false;

    // A new utterance replaces whatever was speaking.
    await stop();
    final completion = Completer<void>();
    _utterance = completion;
    try {
      final started =
          await _channel.invokeMethod<bool>('speak', {
            'text': text,
            'locale': locale,
            'rate': rate,
            'volume': volume,
            'pitch': pitch,
          }) ??
          false;
      if (!started) {
        _finishUtterance();
        return false;
      }
    } on PlatformException {
      _finishUtterance();
      return false;
    }

    await completion.future;
    return true;
  }

  @override
  Future<void> stop() async {
    _finishUtterance();
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // Nothing to stop.
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    _channel.setMethodCallHandler(null);
  }

  void _finishUtterance() {
    final pending = _utterance;
    _utterance = null;
    if (pending != null && !pending.isCompleted) pending.complete();
  }
}
