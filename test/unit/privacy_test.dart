import 'dart:io';

import 'package:avalon_companion/game_engine/engine/game_engine.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/models/phase.dart';
import 'package:avalon_companion/game_engine/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the one rule that cannot be allowed to regress: the app never knows
/// which player holds which character (master plan §2.2, §8, Part 9 privacy
/// tests). These checks read the source itself, so a future feature that adds
/// the link fails here instead of shipping.
void main() {
  final lib = Directory('lib');

  List<File> dartFiles() => lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// Source with comments removed, so prose that mentions the words we guard
  /// against (the docs explain why there is no role mapping) is not a hit.
  ///
  /// The split accepts CRLF: with a trailing `\r` the `$` anchor never matches,
  /// which would leave every comment in place on a Windows checkout.
  String codeOf(File file) {
    final source = file.readAsStringSync();
    final withoutBlocks = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    return withoutBlocks
        .split(RegExp(r'\r?\n'))
        .map((line) => line.replaceAll(RegExp(r'//.*$'), ''))
        .join('\n');
  }

  group('no player-to-character link exists', () {
    test('the player model carries a seat and a name only', () {
      final source = codeOf(File('lib/game_engine/models/player.dart'));

      expect(source.contains('Character'), isFalse,
          reason: 'Player must not reference a character.');
      expect(RegExp(r'\bcharacter\b', caseSensitive: false).hasMatch(source),
          isFalse,
          reason: 'Player must not have a character field.');
      expect(source.contains('Map<int, '), isFalse,
          reason: 'Player must not be the value of a seat-keyed map.');
    });

    test('no source file maps a player or seat to a character', () {
      final mapPatterns = <RegExp>[
        RegExp(r'Map<\s*(Player|int)\s*,\s*Character'),
        RegExp(r'Map<\s*(Player|int)\s*,\s*(Set<\s*)?Character'),
        RegExp(r'<(Player|int)\s*,\s*Character>'),
      ];

      for (final file in dartFiles()) {
        final source = codeOf(file);
        for (final pattern in mapPatterns) {
          expect(pattern.hasMatch(source), isFalse,
              reason: '${file.path} maps a player or seat to a character.');
        }
      }
    });

    test('the game state has no assignment API', () {
      final forbidden = RegExp(
        r'\b(assignRole|assignCharacter|dealRoles|revealRole|'
        r'characterOf|roleOf|playerOfCharacter)\b',
      );

      for (final file in dartFiles()) {
        final source = codeOf(file);
        expect(forbidden.hasMatch(source), isFalse,
            reason: '${file.path} assigns a character to a player.');
      }
    });
  });

  group('assassination records an outcome, not a person', () {
    test('the engine takes a flag and stores a flag', () {
      final source =
          File('lib/game_engine/engine/game_engine.dart').readAsStringSync();
      final state =
          File('lib/game_engine/models/game_state.dart').readAsStringSync();

      expect(source.contains('bool merlinIdentified'), isTrue);
      expect(state.contains('final bool? merlinIdentified'), isTrue);

      for (final forbidden in [
        'merlinSeat',
        'merlinPlayer',
        'assassinatedSeat',
        'targetSeat',
        'targetPlayer',
      ]) {
        expect(state.contains(forbidden), isFalse,
            reason: 'GameState must not record "$forbidden".');
        expect(source.contains(forbidden), isFalse,
            reason: 'GameEngine must not record "$forbidden".');
      }
    });

    test('a resolved match exposes only the flag', () {
      final players = [
        for (var i = 1; i <= 5; i++) Player(seat: i, name: 'P$i'),
      ];
      final game = GameEngine.create(
        players: players,
        composition: Composition(
          playerCount: 5,
          counts: const {
            Character.merlin: 1,
            Character.percival: 1,
            Character.loyalServant: 1,
            Character.assassin: 1,
            Character.morgana: 1,
          },
        ),
      );

      // Preparation is not the assassination; the point is that the public
      // state never exposes a seat-to-character lookup.
      expect(game.phase, Phase.preparation);
      expect(game.playerAtSeat(1), isNotNull);
      expect(
        game.toString().contains('Character.merlin'),
        isFalse,
        reason: 'GameState.toString must not leak characters.',
      );
    });
  });
}
