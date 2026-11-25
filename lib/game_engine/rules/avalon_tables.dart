/// Rule tables — master plan §5.1, §5.2, §5.3. Single source of truth: nothing
/// else in the app may compute these values.
///
/// Avalon is officially a five to ten player game. Rows 11–14 exist only for the
/// Big table setting, which is off by default and is labelled a house rule
/// wherever it is used: the sizes and the roster above ten are ours, not the
/// rulebook's.
abstract final class AvalonTables {
  static const minPlayers = 5;

  /// The largest table the rulebook defines.
  static const officialMaxPlayers = 10;

  /// The largest table the app can track, unlocked by the Big table setting.
  static const maxPlayers = 14;
  static const questCount = 5;

  static const _goodCounts = <int, int>{
    5: 3,
    6: 4,
    7: 4,
    8: 5,
    9: 6,
    10: 6,
    11: 7,
    12: 8,
    13: 8,
    14: 9,
  };

  static const _evilCounts = <int, int>{
    5: 2,
    6: 2,
    7: 3,
    8: 3,
    9: 3,
    10: 4,
    11: 4,
    12: 4,
    13: 5,
    14: 5,
  };

  static const _teamSizes = <int, List<int>>{
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

  /// The largest count setup may offer, given the Big table setting.
  static int maxPlayersFor({required bool bigTable}) =>
      bigTable ? maxPlayers : officialMaxPlayers;

  /// Whether [count] is a house table rather than a size the rulebook knows.
  static bool isHouseTable(int count) => count > officialMaxPlayers;

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
  ///
  /// Above ten players the four named Evil are already in play, so a fifth Evil
  /// seat (a house table at 13 or 14) is filled with a Minion of Mordred.
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
      if (evil > 4) 'Minion of Mordred': evil - 4,
    };
    return composition;
  }
}
