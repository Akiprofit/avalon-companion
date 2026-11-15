/// Alignment and the base-game character pool — master plan §1.4.
enum Allegiance { good, evil }

enum Character {
  merlin('Merlin', Allegiance.good, isUnique: true),
  percival('Percival', Allegiance.good, isUnique: true),
  loyalServant('Loyal Servant of Arthur', Allegiance.good, isUnique: false),
  assassin('Assassin', Allegiance.evil, isUnique: true),
  morgana('Morgana', Allegiance.evil, isUnique: true),
  mordred('Mordred', Allegiance.evil, isUnique: true),
  oberon('Oberon', Allegiance.evil, isUnique: true),
  minionOfMordred('Minion of Mordred', Allegiance.evil, isUnique: false);

  const Character(this.label, this.alignment, {required this.isUnique});

  /// English display name. Kept identical in the Filipino narration, as agreed
  /// in `avalon-narration`.
  final String label;
  final Allegiance alignment;
  final bool isUnique;

  bool get isGood => alignment == Allegiance.good;

  /// Short form used on chips and summaries.
  String get shortLabel => switch (this) {
    Character.loyalServant => 'Loyal Servant',
    Character.minionOfMordred => 'Minion',
    _ => label,
  };

  static List<Character> of(Allegiance alignment) =>
      values.where((c) => c.alignment == alignment).toList();
}
