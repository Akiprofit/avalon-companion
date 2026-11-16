import 'package:avalon_companion/narration_engine/models/narration_instruction.dart';
import 'package:avalon_companion/narration_engine/services/android_clip_service.dart';
import 'package:avalon_companion/narration_engine/services/narration_clips.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Device gate for the recorded narrator.
///
/// The recordings are the narrator, so the one thing that cannot be checked in
/// a widget test is that the MP3s really are inside the APK and that
/// `MediaPlayer` can open them. A compressed or missing asset makes `play`
/// return false, which is the silent fallback to the phone's voice. The clips
/// play at zero volume: this checks decoding and completion, not the speaker.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a recorded night line plays from the bundle', (tester) async {
    final clips = AndroidClipService();
    await clips.initialize();
    expect(
      clips.isAvailable,
      isTrue,
      reason: 'the clip channel answered isAvailable',
    );

    for (final language in NarrationLanguage.values) {
      final played = await clips.play(
        NarrationClips.assetFor('night.end', language),
        volume: 0,
      );
      expect(
        played,
        isTrue,
        reason: 'the ${language.name} recording must decode and finish',
      );
    }

    await clips.dispose();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
