import 'dart:io';

import 'package:avalon_companion/core/constants/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// The About panel and the home footer read [AppInfo.version], so a release
/// that forgets it would tell the MC they are on an older build than the APK.
void main() {
  test('the version shown in the app matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final line = pubspec
        .split('\n')
        .firstWhere((line) => line.startsWith('version:'));
    final declared = line.split(':')[1].trim().split('+').first;

    expect(AppInfo.version, declared);
  });
}
