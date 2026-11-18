import 'package:flutter/services.dart';

/// The platform half of voice import: choosing a zip and finding the folder
/// imported voices live in.
///
/// Nothing here touches the network. The picker opens the system file browser,
/// which hands back a copy of the MC's own file from the phone's storage.
class VoiceImportChannel {
  VoiceImportChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.avalon.companion/voices';

  final MethodChannel _channel;

  /// The absolute directory imported voices are unpacked into, or null when the
  /// platform has no answer (tests, web, a build without the activity).
  Future<String?> directory() async {
    try {
      final path = await _channel.invokeMethod<String>('directory');
      return (path == null || path.isEmpty) ? null : path;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Opens the system file picker for a zip and returns the local copy the
  /// activity made, or null when the MC backed out.
  Future<String?> pickZip() async {
    try {
      final path = await _channel.invokeMethod<String>('pickZip');
      return (path == null || path.isEmpty) ? null : path;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
