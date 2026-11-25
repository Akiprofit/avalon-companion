import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('team composition table', () {
    // 5–10 is the rulebook. 11–14 are the Big table house sizes, so these rows
    // are what the app promises when the MC turns that setting on.
    const expected = {
      5: (3, 2),
      6: (4, 2),
      7: (4, 3),
      8: (5, 3),
      9: (6, 3),
      10: (6, 4),
      11: (7, 4),
      12: (8, 4),
      13: (8, 5),
      14: (9, 5),
    };

    for (final entry in expected.entries) {
      test('${entry.key} players are ${entry.value.$1} good and '
          '${entry.value.$2} evil', () {
        expect(AvalonTables.goodCount(entry.key), entry.value.$1);
        expect(AvalonTables.evilCount(entry.key), entry.value.$2);
      });
    }

    test('player counts outside 5..14 are rejected', () {
      expect(AvalonTables.isValidPlayerCount(4), isFalse);
      expect(AvalonTables.isValidPlayerCount(15), isFalse);
      for (var count = 5; count <= 14; count++) {
        expect(AvalonTables.isValidPlayerCount(count), isTrue, reason: '$count');
      }
    });

    test('only 5..10 is offered unless the Big table setting is on', () {
      expect(AvalonTables.maxPlayersFor(bigTable: false), 10);
      expect(AvalonTables.maxPlayersFor(bigTable: true), 14);
      expect(AvalonTables.officialMaxPlayers, 10);
    });

    test('sizes above ten are marked as house tables', () {
      for (var count = 5; count <= 10; count++) {
        expect(AvalonTables.isHouseTable(count), isFalse, reason: '$count');
      }
      for (var count = 11; count <= 14; count++) {
        expect(AvalonTables.isHouseTable(count), isTrue, reason: '$count');
      }
    });
  });

  group('quest team sizes', () {
    const expected = {
      5: [2, 3, 2, 3, 3],
      6: [2, 3, 4, 3, 4],
      7: [2, 3, 3, 4, 4],
      8: [3, 4, 4, 5, 5],
      9: [3, 4, 4, 5, 5],
      10: [3, 4, 4, 5, 5],
      11: [4, 5, 5, 6, 6],
      12: [4, 5, 5, 6, 6],
      13: [5, 6, 6, 7, 7],
      14: [5, 6, 6, 7, 7],
    };

    for (final entry in expected.entries) {
      test('${entry.key} players use ${entry.value}', () {
        for (var quest = 1; quest <= 5; quest++) {
          expect(
            AvalonTables.teamSize(entry.key, quest),
            entry.value[quest - 1],
            reason: 'quest $quest',
          );
        }
      });
    }
  });

  group('quest failure threshold', () {
    test('quest 4 needs two fails with seven or more players', () {
      for (var count = 7; count <= 14; count++) {
        expect(AvalonTables.failsRequired(count, 4), 2, reason: '$count players');
      }
    });

    test('quest 4 needs one fail with fewer than seven players', () {
      for (final count in [5, 6]) {
        expect(AvalonTables.failsRequired(count, 4), 1, reason: '$count players');
      }
    });

    test('every other quest needs one fail', () {
      for (var count = 5; count <= 14; count++) {
        for (final quest in [1, 2, 3, 5]) {
          expect(AvalonTables.failsRequired(count, quest), 1);
        }
      }
    });
  });

  group('voting majority', () {
    test('a strict majority approves', () {
      expect(AvalonTables.isApproved(3, 2), isTrue);
      expect(AvalonTables.isApproved(5, 3), isTrue);
      expect(AvalonTables.isApproved(4, 3), isTrue);
    });

    test('a tie is rejected', () {
      expect(AvalonTables.isApproved(2, 2), isFalse);
      expect(AvalonTables.isApproved(3, 3), isFalse);
    });

    test('a minority is rejected', () {
      expect(AvalonTables.isApproved(2, 3), isFalse);
    });
  });

  group('composition validation', () {
    Composition compositionFor(int playerCount) {
      final defaults = AvalonTables.defaultComposition(playerCount);
      final counts = <Character, int>{};
      for (final character in Character.values) {
        final value = defaults[character.label];
        if (value != null && value > 0) counts[character] = value;
      }
      return Composition(playerCount: playerCount, counts: counts);
    }

    for (var count = 5; count <= 14; count++) {
      test('the default $count player roster is valid', () {
        final composition = compositionFor(count);
        expect(composition.errors, isEmpty);
        expect(composition.total, count);
        expect(composition.goodTotal, AvalonTables.goodCount(count));
        expect(composition.evilTotal, AvalonTables.evilCount(count));
      });
    }

    test('a fifth Evil seat is a Minion of Mordred', () {
      final defaults = AvalonTables.defaultComposition(14);
      expect(defaults['Minion of Mordred'], 1);
      expect(defaults['Oberon'], 1, reason: 'the four named Evil come first');
      expect(defaults['Loyal Servant of Arthur'], 7);
    });

    test('the house sizes stay near the official Evil share', () {
      for (var count = 11; count <= 14; count++) {
        final share = AvalonTables.evilCount(count) / count;
        expect(share, greaterThan(0.3), reason: '$count players');
        expect(share, lessThan(0.4), reason: '$count players');
      }
    });

    test('a wrong good/evil split is an error', () {
      final composition = Composition(
        playerCount: 5,
        counts: {
          Character.merlin: 1,
          Character.percival: 1,
          Character.loyalServant: 2,
          Character.assassin: 1,
        },
      );
      expect(composition.isValid, isFalse);
      expect(
        composition.errors.map((e) => e.message).join(' '),
        contains('Evil characters'),
      );
    });

    test('Percival without Morgana warns but does not block', () {
      final composition = Composition(
        playerCount: 5,
        counts: {
          Character.merlin: 1,
          Character.percival: 1,
          Character.loyalServant: 1,
          Character.assassin: 1,
          Character.mordred: 1,
        },
      );
      expect(composition.isValid, isTrue);
      expect(
        composition.warnings.map((w) => w.message).join(' '),
        contains('Morgana'),
      );
    });
  });
}
