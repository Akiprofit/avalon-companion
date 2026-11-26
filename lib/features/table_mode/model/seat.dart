/// One seated player, as the board and the other phones see them.
///
/// A seat is a number, a name and whether a phone is holding it. Nothing else:
/// no character, no allegiance, no role, and no timestamp. Phase 1 never learns
/// a character, and later phases will keep the deal in an object that never
/// reaches this class (docs/table-mode.md §6).
///
/// Host bookkeeping — which token owns the seat, when the phone last spoke —
/// lives in `TableSession`, not here, so it cannot be rendered by accident.
class Seat {
  const Seat({
    required this.number,
    required this.name,
    required this.connected,
  });

  /// 1-based, join order, reused when a released seat frees up.
  final int number;
  final String name;

  /// Whether a phone is holding this seat right now. A seat stays in the room
  /// while its phone is away, so a reconnect finds the same number.
  final bool connected;

  Seat copyWith({String? name, bool? connected}) {
    return Seat(
      number: number,
      name: name ?? this.name,
      connected: connected ?? this.connected,
    );
  }

  /// The public shape: exactly what the board and the other phones may know.
  Map<String, Object?> toJson() => {
    'seat': number,
    'name': name,
    'connected': connected,
  };
}
