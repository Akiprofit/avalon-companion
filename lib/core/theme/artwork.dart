/// Bundled cinematic artwork plates — design system §7.
///
/// Every path is relative to the Flutter asset root and must be listed under
/// `flutter: assets:` in `pubspec.yaml`. If a plate is absent, screens fall back
/// to the token gradient, because [CinematicBackground] tolerates a missing
/// asset — but the path must still be added to the manifest before it ships.
abstract final class Artwork {
  static const camelot = 'assets/images/camelot.jpg';
  static const forest = 'assets/images/forest.jpg';
  static const roundTable = 'assets/images/round_table.jpg';
  static const merlinChamber = 'assets/images/merlin_chamber.jpg';
  static const stoneCastle = 'assets/images/stone_castle.jpg';
  static const avalon = 'assets/images/avalon.jpg';
  static const excalibur = 'assets/images/excalibur.jpg';

  /// Every bundled plate, so a test can prove the manifest and the files agree.
  static const all = [
    camelot,
    forest,
    roundTable,
    merlinChamber,
    stoneCastle,
    avalon,
    excalibur,
  ];

  /// Screen → plate mapping, so every screen draws from the same set.
  static const splash = avalon;
  static const home = camelot;
  static const setup = roundTable;
  static const preparation = stoneCastle;
  static const dashboard = roundTable;
  static const narration = merlinChamber;
  static const teamSelection = roundTable;
  static const voting = roundTable;
  static const missionResults = stoneCastle;
  static const assassination = excalibur;
  static const results = avalon;
  static const history = forest;
  static const settings = forest;
}
