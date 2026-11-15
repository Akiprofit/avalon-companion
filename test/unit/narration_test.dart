import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:avalon_companion/narration_engine/scripts/night_script.dart';
import 'package:flutter_test/flutter_test.dart';

Composition compositionFor(int playerCount) {
  final defaults = AvalonTables.defaultComposition(playerCount);
  final counts = <Character, int>{};
  for (final character in Character.values) {
    final value = defaults[character.label];
    if (value != null && value > 0) counts[character] = value;
  }
  return Composition(playerCount: playerCount, counts: counts);
}

void main() {
  group('night sequence', () {
    test('starts by closing eyes and ends at daybreak', () {
      final sequence = NightScript.sequenceFor(compositionFor(5));
      expect(sequence.first.id, 'night.close_eyes');
      expect(sequence.last.id, 'night.end');
    });

    test('five players with Morgana get the two-thumb Percival line', () {
      final ids = NightScript.sequenceFor(compositionFor(5)).map((i) => i.id);
      expect(ids, contains('night.percival.look'));
      expect(ids, isNot(contains('night.percival.look_alone')));
    });

    test('a game with Oberon replaces the plain evil line', () {
      final ids = NightScript.sequenceFor(compositionFor(10)).map((i) => i.id);
      expect(ids, contains('night.evil.look_oberon'));
      expect(ids, isNot(contains('night.evil.look')));
    });

    test('without Oberon the plain evil line is used', () {
      final ids = NightScript.sequenceFor(compositionFor(7)).map((i) => i.id);
      expect(ids, contains('night.evil.look'));
      expect(ids, isNot(contains('night.evil.look_oberon')));
    });

    test('Mordred changes the Merlin line', () {
      final withMordred =
          NightScript.sequenceFor(compositionFor(8)).map((i) => i.id);
      expect(withMordred, contains('night.merlin.look_mordred'));

      final withoutMordred = NightScript.sequenceFor(
        Composition(
          playerCount: 5,
          counts: {
            Character.merlin: 1,
            Character.percival: 1,
            Character.loyalServant: 1,
            Character.assassin: 1,
            Character.morgana: 1,
          },
        ),
      ).map((i) => i.id);
      expect(withoutMordred, contains('night.merlin.look'));
      expect(withoutMordred, isNot(contains('night.merlin.look_mordred')));
    });

    test('a composition without Merlin has no Merlin lines', () {
      final sequence = NightScript.sequenceFor(
        Composition(
          playerCount: 5,
          counts: {
            Character.percival: 1,
            Character.loyalServant: 2,
            Character.assassin: 1,
            Character.morgana: 1,
          },
        ),
      );
      final ids = sequence.map((i) => i.id);
      expect(ids.any((id) => id.contains('merlin')), isFalse);
    });

    test('a composition without Percival has no Percival lines', () {
      final sequence = NightScript.sequenceFor(
        Composition(
          playerCount: 5,
          counts: {
            Character.merlin: 1,
            Character.loyalServant: 2,
            Character.assassin: 1,
            Character.morgana: 1,
          },
        ),
      );
      final ids = sequence.map((i) => i.id);
      expect(ids.any((id) => id.contains('percival')), isFalse);
    });

    test('no instruction names a player or uses a name placeholder', () {
      for (final instruction in NightScript.all) {
        for (final text in [instruction.english, instruction.filipino]) {
          expect(text.contains('{'), isFalse, reason: instruction.id);
          expect(RegExp(r'\b(seat|player)\s*\d', caseSensitive: false)
              .hasMatch(text), isFalse, reason: instruction.id);
        }
      }
    });

    test('every instruction carries both languages', () {
      for (final instruction in NightScript.all) {
        expect(instruction.english.trim(), isNotEmpty);
        expect(instruction.filipino.trim(), isNotEmpty);
        expect(
          instruction.english,
          isNot(instruction.filipino),
          reason: '${instruction.id} is untranslated',
        );
      }
    });
  });
}
