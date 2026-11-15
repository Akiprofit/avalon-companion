import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../database/repositories/pin_repository.dart';

/// Whether a PIN is set, and whether this app session has already opened it.
///
/// Unlocking lasts until the app is closed: the MC types a PIN once, not before
/// every screen. Everything that matters — settings, aborting a match — asks
/// [unlocked] and stops when it is false.
class PinState {
  const PinState({this.hash, this.unlocked = false});

  /// Stored `rounds$salt$digest`, or null when no PIN is set.
  final String? hash;

  /// True when this session already entered the PIN (or no PIN is set).
  final bool unlocked;

  bool get enabled => hash != null && hash!.isNotEmpty;
  bool get locked => enabled && !unlocked;

  PinState copyWith({String? hash, bool? unlocked, bool clearHash = false}) {
    return PinState(
      hash: clearHash ? null : hash ?? this.hash,
      unlocked: unlocked ?? this.unlocked,
    );
  }
}

/// The MC PIN, as the app knows it.
class PinController extends Notifier<PinState> {
  @override
  PinState build() => PinState(hash: ref.watch(initialPinHashProvider));

  /// Checks [pin] against the stored digest and unlocks on a match.
  ///
  /// Returns false for a wrong PIN and for a device with no PIN set, so a
  /// caller can treat "unlock failed" as one case.
  bool submit(String pin) {
    final hash = state.hash;
    if (hash == null || !PinRepository.matches(pin, hash)) return false;
    state = state.copyWith(unlocked: true);
    return true;
  }

  /// Sets or replaces the PIN. The caller has already verified the old one.
  Future<bool> setPin(String pin) async {
    final store = ref.read(pinStoreProvider);
    if (store == null) return false;
    try {
      final stored = await store.save(pin);
      state = PinState(hash: stored, unlocked: true);
      return true;
    } catch (_) {
      // The app stays unlocked and un-PINned; nothing else is affected.
      state = const PinState(unlocked: true);
      return false;
    }
  }

  /// Removes the PIN. The caller has already verified the old one.
  Future<bool> clear() async {
    final store = ref.read(pinStoreProvider);
    state = const PinState(unlocked: true);
    if (store == null) return true;
    try {
      await store.clear();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Locks again, used when the MC leaves the protected area.
  void lock() {
    if (state.enabled) state = state.copyWith(unlocked: false);
  }
}

final pinProvider = NotifierProvider<PinController, PinState>(
  PinController.new,
);

/// Whether the protected area may be opened right now.
final pinUnlockedProvider = Provider<bool>(
  (ref) => !ref.watch(pinProvider).locked,
);
