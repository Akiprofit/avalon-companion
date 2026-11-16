import 'dart:async';

import 'package:flutter/services.dart';

import 'clip_service.dart';

/// Plays the bundled narration recordings over the channel implemented in
/// `MainActivity.kt`.
///
/// The files ship inside the APK and are read straight from the asset bundle:
/// no download, no cache copy, nothing leaves the device.
class AndroidClipService implements ClipService {
  AndroidClipService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_handlePlatformCall);
  }

  static const channelName = 'com.avalon.companion/clips';

  final MethodChannel _channel;

  bool _isAvailable = false;
  bool _initialised = false;
  Completer<bool>? _playing;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Future<void> initialize() async {
    if (_initialised) return;
    _initialised = true;
    try {
      _isAvailable =
          await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      _isAvailable = false;
    } on MissingPluginException {
      _isAvailable = false;
    }
  }

  Future<dynamic> _handlePlatformCall(MethodCall call) async {
    if (call.method == 'onDone' || call.method == 'onError') {
      _finish(played: call.method == 'onDone');
    }
    return null;
  }

  @override
  Future<bool> play(String assetPath, {required double volume}) async {
    await initialize();
    if (!_isAvailable) return false;

    // One narrator at a time: a new clip replaces whatever was playing.
    await stop();
    final completion = Completer<bool>();
    _playing = completion;
    try {
      final started =
          await _channel.invokeMethod<bool>('play', {
            'asset': assetPath,
            'volume': volume,
          }) ??
          false;
      if (!started) {
        _finish(played: false);
        return false;
      }
    } on PlatformException {
      _finish(played: false);
      return false;
    } on MissingPluginException {
      _finish(played: false);
      return false;
    }

    return completion.future;
  }

  @override
  Future<void> stop() async {
    _finish(played: false);
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // Nothing to stop.
    } on MissingPluginException {
      // No player in this build.
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    _channel.setMethodCallHandler(null);
  }

  void _finish({required bool played}) {
    final pending = _playing;
    _playing = null;
    if (pending != null && !pending.isCompleted) pending.complete(played);
  }
}
