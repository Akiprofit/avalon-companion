/// Rule tables — master plan §5.1, §5.2, §5.3. Single source of truth: nothing
/// else in the app may compute these values.
abstract final class AvalonTables {
  static const minPlayers = 5;
  static const maxPlayers = 10;
  static const questCount = 5;

  static const _goodCounts = <int, int>{
    5: 3,
    6: 4,
    7: 4,
    8: 5,
    9: 6,
    10: 6,
  };

  static const _evilCounts = <int, int>{
    5: 2,
    6: 2,
    7: 3,
    8: 3,
    9: 3,
    10: 4,
  };

  static const _teamSizes = <int, List<int>>{
    5: [2, 3, 2, 3, 3],
    6: [2, 3, 4, 3, 4],
    7: [2, 3, 3, 4, 4],
    8: [3, 4, 4, 5, 5],
    9: [3, 4, 4, 5, 5],
    10: [3, 4, 4, 5, 5],
  };

  static bool isValidPlayerCount(int count) =>
      count >= minPlayers && count <= maxPlayers;

  static int goodCount(int playerCount) => _goodCounts[playerCount] ?? 0;

  static int evilCount(int playerCount) => _evilCounts[playerCount] ?? 0;

  /// Team size for a 1-based quest number.
  static int teamSize(int playerCount, int questNumber) {
    final row = _teamSizes[playerCount];
    if (row == null) return 0;
    if (questNumber < 1 || questNumber > questCount) return 0;
    return row[questNumber - 1];
  }

  static List<int> questSizes(int playerCount) =>
      _teamSizes[playerCount] ?? const [];

  /// Fail cards required to fail a quest — §5.3.
  static int failsRequired(int playerCount, int questNumber) =>
      (questNumber == 4 && playerCount >= 7) ? 2 : 1;

  /// Rejected teams in a row that hand the match to Evil — §5.4. A table is
  /// told when one more would do it.
  static const rejectionsBeforeEvil = 5;

  /// Strict majority; a tie is rejected — §5.4.
  static bool isApproved(int approve, int reject) =>
      approve > (approve + reject) / 2;

  /// Default character roster for a player count. This is a *suggestion* the MC
  /// may edit, not a rule: the plan lets the MC choose the composition.
  static Map<String, int> defaultComposition(int playerCount) {
    final good = goodCount(playerCount);
    final evil = evilCount(playerCount);
    final composition = <String, int>{
      'Merlin': 1,
      if (good >= 2) 'Percival': 1,
      if (good > 2) 'Loyal Servant of Arthur': good - 2,
      'Assassin': 1,
      if (evil >= 2) 'Morgana': 1,
      if (evil >= 3) 'Mordred': 1,
      if (evil >= 4) 'Oberon': 1,
    };
    return composition;
  }
}
