import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:avalon_companion/core/constants/app_info.dart';

/// Phase 1 rehearsal of the rule the deal will have to follow: a seat is a
/// number, a name and a presence flag, and nothing on the board can render a
/// character because nothing on the board ever learns one.
///
/// These checks read the source, so a later commit that quietly adds a role to
/// a seat fails here instead of shipping (docs/table-mode.md §6).
void main() {
  final tableMode = Directory('lib/features/table_mode');

  List<File> dartFilesIn(Directory directory) => directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  /// Source with comments removed, so prose that explains the absence of a
  /// character is not mistaken for the presence of one.
  String codeOf(File file) {
    final source = file.readAsStringSync();
    final withoutBlocks = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    return withoutBlocks
        .split(RegExp(r'\r?\n'))
        .map((line) => line.replaceAll(RegExp(r'//.*$'), ''))
        .join('\n');
  }

  test('no Table Mode source names a character, a role or an allegiance', () {
    final forbidden = RegExp(
      r'\b(Character|Merlin|Percival|Morgana|Assassin|Oberon|Mordred|'
      r'evil|role|roles|allegiance)\b',
      caseSensitive: true,
    );

    final files = dartFilesIn(tableMode);
    expect(files, isNotEmpty, reason: 'the feature folder must exist');

    for (final file in files) {
      expect(
        forbidden.hasMatch(codeOf(file)),
        isFalse,
        reason: '${file.path} names a character or a role.',
      );
    }
  });

  test('no Table Mode source imports the game engine', () {
    for (final file in dartFilesIn(tableMode)) {
      final source = codeOf(file);
      expect(
        source.contains('game_engine'),
        isFalse,
        reason: '${file.path} reaches into the match engine.',
      );
    }
  });

  test('the pure layer has no Flutter import, so it runs without a binding', () {
    final pure = <File>[
      ...dartFilesIn(Directory('lib/features/table_mode/model')),
      ...dartFilesIn(Directory('lib/features/table_mode/protocol')),
      File('lib/features/table_mode/host/table_session.dart'),
      File('lib/features/table_mode/host/table_room.dart'),
      File('lib/features/table_mode/player/table_client.dart'),
    ];

    expect(pure, isNotEmpty);
    for (final file in pure) {
      expect(
        codeOf(file).contains('package:flutter'),
        isFalse,
        reason: '${file.path} is not pure Dart.',
      );
    }
  });

  test('GameState gained no Table Mode field', () {
    final source = codeOf(File('lib/game_engine/models/game_state.dart'));

    for (final forbidden in [
      'tableRole',
      'seatToken',
      'roomCode',
      'deviceToken',
      'tableSession',
    ]) {
      expect(
        source.contains(forbidden),
        isFalse,
        reason: 'GameState must not learn "$forbidden".',
      );
    }
  });

  test('the board screen renders the public projection, never a token', () {
    final source = codeOf(
      File('lib/features/table_mode/screens/table_host_screen.dart'),
    );

    expect(source.contains('RoomState'), isTrue);
    for (final forbidden in ['TableSession', 'token', 'connectionId']) {
      expect(
        source.contains(forbidden),
        isFalse,
        reason: 'the board screen must not see "$forbidden".',
      );
    }
  });

  test('a seat serialises exactly three public facts', () {
    final source = codeOf(File('lib/features/table_mode/model/seat.dart'));
    final keys = RegExp(r"'(\w+)':").allMatches(source).map((m) => m[1]).toList();

    expect(keys, ['seat', 'name', 'connected']);
  });

  test('the About copy admits the local network instead of claiming none', () {
    // The app used to say it "works entirely offline". Table Mode makes that a
    // lie the moment a player reads it next to a "Join a Game" button, and the
    // honest sentence is the one that says what leaves the device: nothing.
    expect(AppInfo.privacy.contains('Table Mode'), isTrue);
    expect(AppInfo.privacy.contains('entirely offline'), isFalse);
    expect(AppInfo.privacy.contains('Wi-Fi'), isTrue);
  });

  test('Table Mode opens no network when it is not asked to', () {
    final source = codeOf(
      File('lib/features/table_mode/table_mode_providers.dart'),
    );

    // The only network construct in the provider file is the camera builder's
    // import of mobile_scanner; nothing binds a socket at provider creation.
    expect(source.contains('WebSocket'), isFalse);
    expect(source.contains('RawDatagramSocket'), isFalse);
    expect(source.contains('HttpServer'), isFalse);
  });
}
