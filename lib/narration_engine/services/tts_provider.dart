import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'android_tts_service.dart';
import 'tts_service.dart';

/// The speech engine used by the narration panel. Widget and controller tests
/// override this with a fake, so nothing has to touch a platform channel.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = AndroidTtsService();
  ref.onDispose(service.dispose);
  return service;
});
