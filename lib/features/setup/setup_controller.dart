import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../game_engine/models/character.dart';
import '../../game_engine/models/composition.dart';
import '../../game_engine/rules/avalon_tables.dart';

/// Draft state for the setup screen. Nothing here is a rule — it is the MC's
/// editable working copy until the match starts.
class SetupDraft {
  const SetupDraft({
    required this.playerCount,
    required this.names,
    required this.composition,
  });

  final int playerCount;

  /// One entry per seat, in seating order. Empty string means "not entered yet".
  final List<String> names;
  final Composition composition;

  bool get namesComplete => names.every((n) => n.trim().isNotEmpty);

  List<String> get trimmedNames => names.map((n) => n.trim()).toList();

  bool get hasDuplicateNames {
    final seen = <String>{};
    for (final name in trimmedNames.where((n) => n.isNotEmpty)) {
      if (!seen.add(name.toLowerCase())) return true;
    }
    return false;
  }

  bool get canStart =>
      composition.isValid && namesComplete && !hasDuplicateNames;

  SetupDraft copyWith({
    int? playerCount,
    List<String>? names,
    Composition? composition,
  }) {
    return SetupDraft(
      playerCount: playerCount ?? this.playerCount,
      names: names ?? this.names,
      composition: composition ?? this.composition,
    );
  }
}

class SetupController extends Notifier<SetupDraft> {
  @override
  SetupDraft build() {
    const count = 5;
    return SetupDraft(
      playerCount: count,
      names: List<String>.filled(count, ''),
      composition: _defaultComposition(count),
    );
  }

  static Composition _defaultComposition(int playerCount) {
    final defaults = AvalonTables.defaultComposition(playerCount);
    final counts = <Character, int>{};
    for (final character in Character.values) {
      final value = defaults[character.label];
      if (value != null && value > 0) counts[character] = value;
    }
    return Composition(playerCount: playerCount, counts: counts);
  }

  /// Changing the player count keeps names the MC already typed and rebuilds the
  /// default composition for the new count.
  void setPlayerCount(int count) {
    if (!AvalonTables.isValidPlayerCount(count)) return;
    final names = List<String>.generate(
      count,
      (i) => i < state.names.length ? state.names[i] : '',
    );
    state = state.copyWith(
      playerCount: count,
      names: names,
      composition: _defaultComposition(count),
    );
  }

  void setName(int seat, String name) {
    final names = List<String>.from(state.names);
    if (seat < 0 || seat >= names.length) return;
    names[seat] = name;
    state = state.copyWith(names: names);
  }

  void setCharacterCount(Character character, int value) {
    if (value < 0) return;
    if (character.isUnique && value > 1) return;
    state = state.copyWith(
      composition: state.composition.withCount(character, value),
    );
  }

  void reset() {
    state = build();
  }
}

final setupProvider = NotifierProvider<SetupController, SetupDraft>(
  SetupController.new,
);

/// The names at the most recent match, for **Use the last table**.
///
/// Names only, in seat order: the store has no role per player to restore.
final lastRosterProvider = FutureProvider<List<String>>((ref) async {
  final store = ref.watch(matchStoreProvider);
  if (store == null) return const [];
  return store.lastRoster();
});
