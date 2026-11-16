import 'dart:io';

import 'package:avalon_companion/narration_engine/models/narration_instruction.dart';
import 'package:avalon_companion/narration_engine/scripts/night_script.dart';
import 'package:avalon_companion/narration_engine/services/narration_clips.dart';
import 'package:flutter_test/flutter_test.dart';

/// The recordings are the narrator, so a missing file is not a cosmetic
/// problem: it would drop the night back to the phone's voice mid-match.
void main() {
  test('every night line has an English and a Filipino recording', () {
    for (final line in NightScript.all) {
      for (final language in NarrationLanguage.values) {
        final path = NarrationClips.assetFor(line.id, language);
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path is missing');
        expect(
          file.lengthSync(),
          greaterThan(1024),
          reason: '$path is empty or truncated',
        );
      }
    }
  });

  test('the recorded set and the night script list the same lines', () {
    final scripted = NightScript.all.map((line) => line.id).toSet();
    expect(
      NarrationClips.ids.difference(scripted),
      isEmpty,
      reason: 'a recorded id has no line to attach to',
    );
    expect(
      scripted.difference(NarrationClips.ids),
      isEmpty,
      reason: 'a night line has no recording',
    );
  });

  test('the clips live in the language folders the app reads', () {
    expect(
      NarrationClips.assetFor('night.end', NarrationLanguage.english),
      'assets/audio/narration/en/night.end.mp3',
    );
    expect(
      NarrationClips.assetFor('night.end', NarrationLanguage.filipino),
      'assets/audio/narration/fil/night.end.mp3',
    );
    expect(NarrationClips.directory, Directory('assets/audio/narration').path);
  });

  test('no round line has a recording yet', () {
    for (final id in const [
      'round.proposal',
      'vote.approved',
      'vote.rejected',
      'vote.rejection_warning',
      'quest.success',
      'quest.fail',
      'assassination.begin',
    ]) {
      expect(NarrationClips.has(id), isFalse, reason: '$id has no recording');
    }
  });

  test('pubspec bundles each language folder', () {
    // Flutter asset folders are not recursive. Listing only the parent folder
    // ships this README and no audio, and the app silently falls back to the
    // phone's voice — the APK was checked once and told the difference.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final language in NarrationLanguage.values) {
      final folder = NarrationClips.folderFor(language);
      expect(
        pubspec.contains('${NarrationClips.directory}/$folder/'),
        isTrue,
        reason: 'pubspec.yaml must list assets/audio/narration/$folder/',
      );
    }
  });
}
