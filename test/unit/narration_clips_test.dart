import 'dart:io';

import 'package:avalon_companion/narration_engine/models/narration_instruction.dart';
import 'package:avalon_companion/narration_engine/scripts/night_script.dart';
import 'package:avalon_companion/narration_engine/scripts/round_script.dart';
import 'package:avalon_companion/narration_engine/services/narration_clips.dart';
import 'package:flutter_test/flutter_test.dart';

/// The recordings are the narrator, so a missing file is not a cosmetic
/// problem: it would drop the line back to the phone's voice mid-match.
void main() {
  void expectRecorded(NarrationInstruction line) {
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

  test('every night line has an English and a Filipino recording', () {
    for (final line in NightScript.all) {
      expectRecorded(line);
    }
  });

  test('every round line has an English and a Filipino recording', () {
    for (final line in RoundScript.all) {
      expectRecorded(line);
    }
  });

  test('the recorded set is exactly the night and the round lines', () {
    final scripted = {
      for (final line in NightScript.all) line.id,
      for (final line in RoundScript.all) line.id,
    };
    expect(
      NarrationClips.ids.difference(scripted),
      isEmpty,
      reason: 'a recorded id has no line to attach to',
    );
    expect(
      scripted.difference(NarrationClips.ids),
      isEmpty,
      reason: 'a scripted line has no recording',
    );
  });

  test('the round ids are the ones the cues announce', () {
    // The cue player looks a line up by id, so an id that drifts from the
    // script would silently fall back to the phone's voice.
    for (final id in const [
      'round.proposal',
      'vote.approved',
      'vote.rejected',
      'vote.rejection_warning',
      'quest.success',
      'quest.fail',
      'assassination.begin',
    ]) {
      expect(NarrationClips.has(id), isTrue, reason: '$id is not announced');
    }
  });

  test('the clips live in the narrator folders the app reads', () {
    expect(
      NarrationClips.assetFor('night.end', NarrationLanguage.english),
      'assets/audio/narration/Dahlia voices/en/night.end.mp3',
    );
    expect(
      NarrationClips.assetFor('night.end', NarrationLanguage.filipino),
      'assets/audio/narration/Dahlia voices/fil/night.end.mp3',
    );
    expect(
      NarrationClips.directory,
      Directory('assets/audio/narration/Dahlia voices').path,
    );
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
        reason: 'pubspec.yaml must list ${NarrationClips.directory}/$folder/',
      );
    }
  });
}
