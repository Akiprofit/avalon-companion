/// Route names and paths. The router is the only place that knows these strings.
abstract final class RouteNames {
  static const splash = 'splash';
  static const home = 'home';
  static const setup = 'setup';
  static const preparation = 'preparation';
  static const dashboard = 'dashboard';
  static const narration = 'narration';
  static const lordSelection = 'lordSelection';
  static const teamSelection = 'teamSelection';
  static const voting = 'voting';
  static const questResolution = 'questResolution';
  static const assassination = 'assassination';
  static const results = 'results';
  static const history = 'history';
  static const howToPlay = 'howToPlay';
  static const settings = 'settings';

  /// Table Mode. The board hosts, the phones join, the seat is where a phone
  /// rests. None of these need a `GameState`.
  static const tableHost = 'tableHost';
  static const join = 'join';
  static const joinScan = 'joinScan';
  static const playerSeat = 'playerSeat';
}

abstract final class RoutePaths {
  static const splash = '/';
  static const home = '/home';
  static const setup = '/setup';
  static const preparation = '/preparation';
  static const dashboard = '/game';
  static const narration = '/game/narration';
  static const lordSelection = '/game/lord';
  static const teamSelection = '/game/team-selection';
  static const voting = '/game/voting';
  static const questResolution = '/game/quest';
  static const assassination = '/game/assassination';
  static const results = '/game/results';
  static const history = '/history';
  static const howToPlay = '/how-to-play';
  static const settings = '/settings';
  static const tableHost = '/table';
  static const join = '/join';
  static const joinScan = '/join/scan';
  static const playerSeat = '/seat';
}
