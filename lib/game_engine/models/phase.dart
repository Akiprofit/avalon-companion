/// States from master plan §5.7. Exhaustive switches are required everywhere.
enum Phase {
  setup('Setup'),
  preparation('Preparation'),
  night('Night'),
  lordSelection('Choose the Lord'),
  dayDiscussion('Day'),
  teamSelection('Team Selection'),
  teamVoting('Team Voting'),
  questResolution('Quest Resolution'),
  assassination('Assassination'),
  goodVictory('Good Victory'),
  evilVictory('Evil Victory'),
  paused('Paused');

  const Phase(this.label);

  final String label;

  bool get isVictory => this == goodVictory || this == evilVictory;
  bool get isActive => !isVictory && this != setup && this != preparation;
}
