import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../app_database.dart';

/// The optional MC PIN.
///
/// The digits are never stored or logged: what lands in the `Settings` row is
/// `rounds$salt$digest`, a salted SHA-256 that can only answer "is this the
/// same PIN?". A four-digit PIN is a lock on the table — it keeps a curious
/// player out of the settings and away from Abort — not a password vault, so
/// this is deliberately the whole mechanism. Nothing here ever touches a
/// player's name or a character.
class PinRepository {
  PinRepository(this._db, {Random? random})
    : _random = random ?? Random.secure();

  final AppDatabase _db;
  final Random _random;

  /// Number of digest rounds. Enough to make a table-side guess slow, small
  /// enough that unlocking never feels like a wait.
  static const rounds = 20000;

  /// Stored value, or null when no PIN is set.
  Future<String?> loadHash() async {
    final row = await (_db.select(_db.settings)
          ..where((s) => s.id.equals(1)))
        .getSingleOrNull();
    final hash = row?.mcPinHash;
    return hash == null || hash.isEmpty ? null : hash;
  }

  /// Sets [pin] for the first time or replaces an existing one.
  ///
  /// Returns the value it stored, so the caller can keep its state identical to
  /// the row without hashing twice.
  Future<String> save(String pin) async {
    final value = encode(pin, random: _random);
    await _write(mcPinHash: Value(value), enabled: true);
    return value;
  }

  /// Forgets the PIN entirely.
  Future<void> clear() => _write(mcPinHash: const Value(null), enabled: false);

  Future<void> _write({
    required Value<String?> mcPinHash,
    required bool enabled,
  }) {
    return _db.transaction(() async {
      final companion = SettingsCompanion(
        id: const Value(1),
        mcPinHash: mcPinHash,
        mcPinEnabled: Value(enabled),
      );
      final updated = await (_db.update(_db.settings)
            ..where((s) => s.id.equals(1)))
          .write(companion);
      if (updated == 0) {
        await _db.into(_db.settings).insert(companion);
      }
    });
  }

  /// Pure: `rounds$salt$digest`, all hex except the round count.
  static String encode(String pin, {Random? random}) {
    final rng = random ?? Random.secure();
    final salt = List<int>.generate(16, (_) => rng.nextInt(256));
    final saltHex = _hex(salt);
    return '$rounds\$$saltHex\$${_digest(pin, saltHex)}';
  }

  /// Pure: whether [pin] matches a stored [encoded] value.
  ///
  /// Anything malformed is treated as no match, so a damaged row locks rather
  /// than silently opens.
  static bool matches(String pin, String encoded) {
    final parts = encoded.split(r'$');
    if (parts.length != 3) return false;
    final rounds = int.tryParse(parts[0]);
    if (rounds == null || rounds < 1) return false;
    return _digest(pin, parts[1], iterations: rounds) == parts[2];
  }

  static String _digest(String pin, String saltHex, {int iterations = rounds}) {
    var bytes = utf8.encode('$saltHex:$pin').toList();
    for (var i = 0; i < iterations; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return _hex(bytes);
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
