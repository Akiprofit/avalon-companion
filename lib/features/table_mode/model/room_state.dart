import 'seat.dart';

/// Where the room is in its life.
///
/// Phase 1 has one value. `dealing` and the match phases arrive with Phase 2;
/// the field exists now so the wire shape does not have to change then.
enum RoomPhase {
  lobby('lobby');

  const RoomPhase(this.wire);

  final String wire;

  static RoomPhase fromWire(String? value) {
    for (final phase in values) {
      if (phase.wire == value) return phase;
    }
    return lobby;
  }
}

/// The board's public projection of the room.
///
/// This is the only room object a widget may see. It has no device token and no
/// seat-to-role map — the object that holds those is `TableSession`, which never
/// reaches the widget tree. That split is the Phase 1 rehearsal of the privacy
/// rule the deal will have to follow later.
class RoomState {
  const RoomState({
    required this.code,
    required this.address,
    required this.port,
    required this.capacity,
    required this.seats,
    this.phase = RoomPhase.lobby,
  });

  /// The six-character code the board prints.
  final String code;

  /// The LAN address the board is serving on, e.g. `192.168.43.1`.
  final String address;

  final int port;
  final int capacity;

  /// Seats in join order, so the board reads top to bottom like the table.
  final List<Seat> seats;

  final RoomPhase phase;

  int get seatedCount => seats.length;

  bool get isEmpty => seats.isEmpty;

  bool get isFull => seats.length >= capacity;

  Seat? seatAt(int number) {
    for (final seat in seats) {
      if (seat.number == number) return seat;
    }
    return null;
  }

  /// The seat holding [name], case-insensitively, or null.
  Seat? seatNamed(String name) {
    final needle = name.trim().toLowerCase();
    for (final seat in seats) {
      if (seat.name.toLowerCase() == needle) return seat;
    }
    return null;
  }

  /// The lowest free seat number, or null when the room is full.
  int? get nextFreeSeat {
    for (var number = 1; number <= capacity; number++) {
      if (seatAt(number) == null) return number;
    }
    return null;
  }

  RoomState copyWith({
    String? code,
    String? address,
    int? port,
    int? capacity,
    List<Seat>? seats,
    RoomPhase? phase,
  }) {
    return RoomState(
      code: code ?? this.code,
      address: address ?? this.address,
      port: port ?? this.port,
      capacity: capacity ?? this.capacity,
      seats: seats ?? this.seats,
      phase: phase ?? this.phase,
    );
  }

  /// The `state` payload, shared by `welcome` and `state`.
  List<Map<String, Object?>> get seatsJson => [
    for (final seat in seats) seat.toJson(),
  ];
}
