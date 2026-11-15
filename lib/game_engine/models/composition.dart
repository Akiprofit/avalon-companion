import '../rules/avalon_tables.dart';
import 'character.dart';

enum IssueSeverity { error, warning }

class CompositionIssue {
  const CompositionIssue(this.severity, this.message);

  final IssueSeverity severity;
  final String message;

  bool get isError => severity == IssueSeverity.error;
}

/// Composition validation. Hard errors block the match from starting; warnings
/// are shown as plain sentences and block nothing.
class Composition {
  Composition({required this.playerCount, required Map<Character, int> counts})
    : counts = Map<Character, int>.unmodifiable({
        for (final entry in counts.entries)
          if (entry.value > 0) entry.key: entry.value,
      });

  final int playerCount;

  /// Characters in play and how many of each. Never attached to a player.
  final Map<Character, int> counts;

  int get goodTotal => counts.entries
      .where((e) => e.key.isGood)
      .fold(0, (sum, e) => sum + e.value);

  int get evilTotal => counts.entries
      .where((e) => !e.key.isGood)
      .fold(0, (sum, e) => sum + e.value);

  int get total => goodTotal + evilTotal;

  bool get hasMerlin => counts.containsKey(Character.merlin);
  bool get hasPercival => counts.containsKey(Character.percival);
  bool get hasMorgana => counts.containsKey(Character.morgana);
  bool get hasMordred => counts.containsKey(Character.mordred);
  bool get hasOberon => counts.containsKey(Character.oberon);
  bool get hasAssassin => counts.containsKey(Character.assassin);

  bool has(Character character) => (counts[character] ?? 0) > 0;

  int countOf(Character character) => counts[character] ?? 0;

  Composition withCount(Character character, int value) {
    final next = Map<Character, int>.from(counts);
    if (value <= 0) {
      next.remove(character);
    } else {
      next[character] = value;
    }
    return Composition(playerCount: playerCount, counts: next);
  }

  Composition withPlayerCount(int count) => Composition(
    playerCount: count,
    counts: counts,
  );

  /// All issues, errors first.
  List<CompositionIssue> validate() {
    final issues = <CompositionIssue>[];

    if (!AvalonTables.isValidPlayerCount(playerCount)) {
      issues.add(
        const CompositionIssue(
          IssueSeverity.error,
          'Choose between 5 and 10 players.',
        ),
      );
      return issues;
    }

    final requiredGood = AvalonTables.goodCount(playerCount);
    final requiredEvil = AvalonTables.evilCount(playerCount);

    if (goodTotal != requiredGood) {
      issues.add(
        CompositionIssue(
          IssueSeverity.error,
          'Good characters: $goodTotal selected, $requiredGood needed '
          'for $playerCount players.',
        ),
      );
    }

    if (evilTotal != requiredEvil) {
      issues.add(
        CompositionIssue(
          IssueSeverity.error,
          'Evil characters: $evilTotal selected, $requiredEvil needed '
          'for $playerCount players.',
        ),
      );
    }

    for (final entry in counts.entries) {
      if (entry.key.isUnique && entry.value > 1) {
        issues.add(
          CompositionIssue(
            IssueSeverity.error,
            '${entry.key.label} can only appear once.',
          ),
        );
      }
    }

    if (!hasMerlin) {
      issues.add(
        const CompositionIssue(
          IssueSeverity.warning,
          'Without Merlin, the Assassin has nothing to hunt and assassination '
          'is a formality.',
        ),
      );
    }

    if (hasPercival && !hasMorgana) {
      issues.add(
        const CompositionIssue(
          IssueSeverity.warning,
          'Percival has no Morgana to be confused by in this composition.',
        ),
      );
    }

    if (hasMorgana && !hasPercival) {
      issues.add(
        const CompositionIssue(
          IssueSeverity.warning,
          'Morgana can only mislead Merlin; Percival is not in play.',
        ),
      );
    }

    if (hasMordred && !hasMerlin) {
      issues.add(
        const CompositionIssue(
          IssueSeverity.warning,
          'Mordred only matters when Merlin is in play.',
        ),
      );
    }

    if (!hasAssassin) {
      issues.add(
        const CompositionIssue(
          IssueSeverity.warning,
          'No Assassin in play: the MC still conducts the accusation, '
          'but no player holds the card.',
        ),
      );
    }

    if (evilTotal == 0) {
      issues.add(
        const CompositionIssue(
          IssueSeverity.error,
          'At least one evil character is required.',
        ),
      );
    }

    issues.sort((a, b) => a.isError == b.isError ? 0 : (a.isError ? -1 : 1));
    return issues;
  }

  List<CompositionIssue> get errors =>
      validate().where((i) => i.isError).toList();

  List<CompositionIssue> get warnings =>
      validate().where((i) => !i.isError).toList();

  bool get isValid => errors.isEmpty;
}
