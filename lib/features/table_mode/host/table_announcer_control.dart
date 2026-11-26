/// The board's LAN announcement, as the controller sees it.
///
/// Discovery is an optimisation: the QR carries the address, and the join screen
/// accepts a typed one. A test — or a network that refuses broadcast — gets a
/// control that simply reports "not started", and the room still works.
abstract interface class TableAnnouncerControl {
  /// Starts announcing. False means broadcast is unavailable here.
  Future<bool> start();

  Future<void> stop();
}
