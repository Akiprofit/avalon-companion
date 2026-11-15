import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the Android host can do for the table beyond drawing pixels.
///
/// Two things need the activity rather than the widget tree: keeping the screen
/// on during a live match is a window flag, and the night ambience is a looping
/// audio track. Both are optional — a test, or a platform without the channel,
/// gets [NoHostServices] and the app plays exactly the same match.
abstract interface class HostServices {
  /// Keeps the display awake while [enabled], then lets it sleep again.
  Future<void> setKeepAwake(bool enabled);

  /// Starts or stops the night ambience loop.
  Future<void> setAmbient(bool enabled);
}

/// Talks to `com.avalon.companion/host` in `MainActivity`.
///
/// Calls are fire-and-forget: a missing channel must never surface as an error
/// on a screen the MC is using at the table.
class AndroidHostServices implements HostServices {
  const AndroidHostServices();

  static const _channel = MethodChannel('com.avalon.companion/host');

  @override
  Future<void> setKeepAwake(bool enabled) => _send('setKeepAwake', enabled);

  @override
  Future<void> setAmbient(bool enabled) => _send('setAmbient', enabled);

  Future<void> _send(String method, bool value) async {
    try {
      await _channel.invokeMethod<void>(method, value);
    } on PlatformException {
      // The activity said no (or has gone): the match still runs.
    } on MissingPluginException {
      // Not an Android host — nothing to do.
    }
  }
}

/// Does nothing, on purpose. The default so widget tests stay hermetic and a
/// platform failure never blocks a match.
class NoHostServices implements HostServices {
  const NoHostServices();

  @override
  Future<void> setKeepAwake(bool enabled) async {}

  @override
  Future<void> setAmbient(bool enabled) async {}
}

/// Native host services. Replaced in bootstrap; the no-op default keeps widget
/// tests free of platform channels.
final hostServicesProvider = Provider<HostServices>(
  (ref) => const NoHostServices(),
);
