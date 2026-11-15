import '../../game_engine/models/phase.dart';

/// One spoken instruction — master plan §6.1. Both languages live beside each
/// other so the narration panel can switch without reloading anything.
class NarrationInstruction {
  const NarrationInstruction({
    required this.id,
    required this.phase,
    required this.heading,
    required this.english,
    required this.filipino,
    this.requiresCharacters = const [],
    this.pauseAfter = const Duration(milliseconds: 900),
  });

  final String id;
  final Phase phase;

  /// Character or phase heading shown above the line, e.g. "MERLIN".
  final String heading;
  final String english;
  final String filipino;

  /// Character labels that must all be in the composition for this line to play.
  /// Empty means it always plays.
  final List<String> requiresCharacters;
  final Duration pauseAfter;

  bool appliesTo(Set<String> composition) =>
      requiresCharacters.every(composition.contains);

  String textFor(NarrationLanguage language) =>
      language == NarrationLanguage.filipino ? filipino : english;
}

enum NarrationLanguage {
  english('English', 'en-GB'),
  filipino('Filipino', 'fil-PH');

  const NarrationLanguage(this.label, this.localeCode);

  final String label;
  final String localeCode;
}
