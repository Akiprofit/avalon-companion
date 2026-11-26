/// What this device is for, remembered between launches.
///
/// Chosen once per device, not per build: a tablet that lives on the table is
/// the board, a player's phone is a phone. The solo companion is the default so
/// an install that never touches Table Mode looks and behaves exactly as it did
/// before this feature existed.
///
/// It lives in `core/models` next to [AppSettings] because it is a persisted
/// preference, not a Table Mode internal: the database layer maps it without
/// importing a screen-facing controller.
enum TableRole {
  /// `New Game` / `Continue Game` only, plus the two table entries on Home.
  solo('Solo companion'),

  /// This device hosts the room and shows the board.
  board('The board'),

  /// This device joins a room and shows one player's seat.
  player('A player phone');

  const TableRole(this.label);

  /// Shown in Settings, so the choice is never a mystery.
  final String label;

  /// The stored name, tolerant of a value written by a newer build.
  static TableRole fromStorage(String? value) {
    for (final role in values) {
      if (role.name == value) return role;
    }
    return solo;
  }
}
