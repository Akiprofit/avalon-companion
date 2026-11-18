import 'dart:convert';

import 'package:drift/drift.dart';

import '../../narration_engine/models/voice_pack.dart';
import '../app_database.dart';

/// Reads and writes the narrator voices in the `VoicePacks` table.
///
/// The files themselves never live in the database: this stores the name, the
/// folder, and which line ids each language can play. A voice whose files have
/// been deleted still loads, and simply falls back to text-to-speech line by
/// line — a setting is not worth a crash.
class VoicePackRepository {
  VoicePackRepository(this._db);

  final AppDatabase _db;

  Future<List<VoicePack>> loadAll() async {
    final rows = await (_db.select(
      _db.voicePacks,
    )..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
    return [for (final row in rows) decode(row)];
  }

  Future<void> save(VoicePack pack) async {
    await _db.into(_db.voicePacks).insertOnConflictUpdate(encode(pack));
  }

  Future<void> saveAll(Iterable<VoicePack> packs) async {
    final rows = [for (final pack in packs) encode(pack)];
    if (rows.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.voicePacks, rows);
    });
  }

  Future<void> rename(String id, String name) async {
    await (_db.update(_db.voicePacks)..where((t) => t.id.equals(id))).write(
      VoicePacksCompanion(name: Value(name)),
    );
  }

  Future<void> setHidden(String id, bool hidden) async {
    await (_db.update(_db.voicePacks)..where((t) => t.id.equals(id))).write(
      VoicePacksCompanion(hidden: Value(hidden)),
    );
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.voicePacks)..where((t) => t.id.equals(id))).go();
  }

  /// Pure mapping, so the stored shape can be tested without a database.
  static VoicePacksCompanion encode(VoicePack pack) {
    return VoicePacksCompanion.insert(
      id: pack.id,
      name: pack.name,
      clips: Value(encodeClips(pack.clips)),
      builtIn: Value(pack.builtIn),
      hidden: Value(pack.hidden),
      root: Value(pack.root),
      createdAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Pure mapping back to the app model, tolerant of a newer stored shape.
  static VoicePack decode(VoicePackRecord row) {
    return VoicePack(
      id: row.id,
      name: row.name,
      root: row.root,
      clips: decodeClips(row.clips),
      builtIn: row.builtIn,
      hidden: row.hidden,
    );
  }

  static String encodeClips(Map<String, Set<String>> clips) {
    return jsonEncode({
      for (final entry in clips.entries)
        if (entry.value.isNotEmpty)
          entry.key: (entry.value.toList()..sort()),
    });
  }

  static Map<String, Set<String>> decodeClips(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final out = <String, Set<String>>{};
      decoded.forEach((key, value) {
        if (key is! String || value is! List) return;
        final ids = {
          for (final id in value)
            if (id is String && id.isNotEmpty) id,
        };
        // An empty language is the same as an absent one: the line falls back
        // to text-to-speech either way, so do not make the caller check both.
        if (ids.isEmpty) return;
        out[key] = ids;
      });
      return out;
    } catch (_) {
      return const {};
    }
  }
}
