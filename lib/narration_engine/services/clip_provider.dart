import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'android_clip_service.dart';
import 'clip_service.dart';

/// The player used for the recorded narration. Tests override it with a fake,
/// so nothing has to touch a platform channel.
final clipServiceProvider = Provider<ClipService>((ref) {
  final service = AndroidClipService();
  ref.onDispose(service.dispose);
  return service;
});
