/// One seated player. Public information only — there is deliberately no
/// character field anywhere on a player (master plan §2.1, §2.2, §8).
class Player {
  const Player({required this.seat, required this.name});

  final int seat;
  final String name;

  String get displayName => name.trim().isEmpty ? 'Seat $seat' : name.trim();

  Player copyWith({String? name}) => Player(seat: seat, name: name ?? this.name);

  @override
  bool operator ==(Object other) =>
      other is Player && other.seat == seat && other.name == name;

  @override
  int get hashCode => Object.hash(seat, name);
}
