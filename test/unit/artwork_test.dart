import 'package:avalon_companion/core/theme/artwork.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The cinematic pass is only real if the plates ship. These tests keep the
/// `Artwork` map, the manifest and the files on disk in agreement.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every plate is bundled, a JPEG, and portrait', () async {
    for (final path in Artwork.all) {
      final data = await rootBundle.load(path);
      expect(
        data.lengthInBytes,
        greaterThan(50 * 1024),
        reason: '$path should be a full-size plate, not a placeholder',
      );
      final bytes = data.buffer.asUint8List();
      expect(bytes[0], 0xFF, reason: '$path is not a JPEG');
      expect(bytes[1], 0xD8, reason: '$path is not a JPEG');

      final size = _jpegSize(bytes);
      expect(size, isNotNull, reason: '$path has no readable JPEG header');
      expect(
        size!.$2,
        greaterThan(size.$1),
        reason: '$path must be a portrait plate (height > width)',
      );
    }
  });

  test('the total artwork budget stays under 2 MB', () async {
    var total = 0;
    for (final path in Artwork.all) {
      total += (await rootBundle.load(path)).lengthInBytes;
    }
    expect(
      total,
      lessThan(2 * 1024 * 1024),
      reason: 'the brief caps the bundled plates at 2 MB',
    );
  });

  test('every screen maps to a plate in the set', () {
    const screens = [
      Artwork.splash,
      Artwork.home,
      Artwork.setup,
      Artwork.preparation,
      Artwork.dashboard,
      Artwork.narration,
      Artwork.teamSelection,
      Artwork.voting,
      Artwork.missionResults,
      Artwork.assassination,
      Artwork.results,
      Artwork.history,
      Artwork.settings,
    ];
    for (final plate in screens) {
      expect(Artwork.all, contains(plate));
    }
  });
}

/// Width and height from the SOF marker of a JPEG, or null when malformed.
(int, int)? _jpegSize(List<int> bytes) {
  var index = 2;
  while (index + 9 < bytes.length) {
    if (bytes[index] != 0xFF) {
      index++;
      continue;
    }
    final marker = bytes[index + 1];
    final length = (bytes[index + 2] << 8) + bytes[index + 3];
    final isStartOfFrame =
        marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8;
    if (isStartOfFrame) {
      final height = (bytes[index + 5] << 8) + bytes[index + 6];
      final width = (bytes[index + 7] << 8) + bytes[index + 8];
      return (width, height);
    }
    index += 2 + length;
  }
  return null;
}
