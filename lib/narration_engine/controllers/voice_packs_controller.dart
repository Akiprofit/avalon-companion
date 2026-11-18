import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../database/repositories/voice_pack_repository.dart';
import '../models/voice_pack.dart';
import '../services/voice_files.dart';
import '../services/voice_import.dart';
import '../services/voice_import_channel.dart';
import '../services/voice_pack_catalogue.dart';
import '../services/voice_providers.dart';

/// The narrator voices this device offers, and the one the settings point at.
class VoicePacksState {
  const VoicePacksState({this.packs = const [], this.loaded = false});

  /// Bundled voices first, then imported ones in the order they arrived.
  final List<VoicePack> packs;

  /// False until the bundle and the database have both been read. The app is
  /// usable before that: [active] already answers with the shipped voice.
  final bool loaded;

  List<VoicePack> get visible => [
    for (final pack in packs)
      if (!pack.hidden) pack,
  ];

  List<VoicePack> get hidden => [
    for (final pack in packs)
      if (pack.hidden) pack,
  ];

  VoicePack? byId(String? id) {
    if (id == null) return null;
    for (final pack in packs) {
      if (pack.id == id) return pack;
    }
    return null;
  }

  /// The voice to narrate with.
  ///
  /// An unknown id — a pack deleted on another install, a rename that went
  /// wrong — falls back to the shipped recordings rather than to silence.
  VoicePack active(String? id) =>
      byId(id) ??
      byId(VoicePackCatalogue.classicId) ??
      VoicePackCatalogue.classic;

  VoicePacksState copyWith({List<VoicePack>? packs, bool? loaded}) {
    return VoicePacksState(
      packs: packs ?? this.packs,
      loaded: loaded ?? this.loaded,
    );
  }
}

/// Reads the bundled voices, merges the MC's renames and hides, and installs
/// imported packs into app storage.
///
/// A voice is a folder of recordings, so this never deals with a single file:
/// it deals with a pack, its name, and which lines it can read.
class VoicePacksController extends Notifier<VoicePacksState> {
  @override
  VoicePacksState build() {
    // Before anything has been read, behave exactly like the shipped app: one
    // voice, every night line.
    return VoicePacksState(packs: [VoicePackCatalogue.classic]);
  }

  VoicePackRepository? get _store => ref.read(voicePackStoreProvider);
  VoiceFiles get _files => ref.read(voiceFilesProvider);
  VoiceImportChannel get _channel => ref.read(voiceImportChannelProvider);

  /// Reads the bundle and the stored rows. Safe to call more than once.
  Future<void> refresh() async {
    final bundled = await VoicePackCatalogue.load();
    final store = _store;
    if (store == null) {
      state = VoicePacksState(packs: bundled, loaded: true);
      return;
    }

    List<VoicePack> stored;
    try {
      stored = await store.loadAll();
    } catch (_) {
      // Storage trouble must not cost the MC the narrator.
      state = VoicePacksState(packs: bundled, loaded: true);
      return;
    }

    final merged = _merge(bundled, stored);

    // Keep the table in step with the build: new bundled voices get a row so
    // they can be renamed, and rows for voices this build no longer ships are
    // dropped so the list never offers a folder that is not there.
    try {
      final known = stored.map((pack) => pack.id).toSet();
      final added = merged.where(
        (pack) => pack.builtIn && !known.contains(pack.id),
      );
      if (added.isNotEmpty) await store.saveAll(added);
      for (final pack in stored) {
        if (!pack.builtIn) continue;
        if (bundled.any((built) => built.id == pack.id)) continue;
        await store.delete(pack.id);
      }
    } catch (_) {
      // A read-only database still narrates; the next launch retries.
    }

    state = VoicePacksState(packs: merged, loaded: true);
  }

  /// Renames a voice. The folder is untouched: only the label changes.
  Future<void> rename(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final pack = state.byId(id);
    if (pack == null || pack.name == trimmed) return;
    try {
      await _store?.rename(id, trimmed);
    } catch (_) {
      // Keep the new name in memory; the next launch retries the write.
    }
    state = state.copyWith(
      packs: [
        for (final existing in state.packs)
          if (existing.id == id) existing.copyWith(name: trimmed) else existing,
      ],
    );
  }

  /// Takes a voice out of the list without deleting its files.
  ///
  /// That is the only option for the bundled recordings — they live inside the
  /// installed app — and it is what "keep only my voice" means in practice.
  Future<void> setHidden(String id, bool hidden) async {
    final pack = state.byId(id);
    if (pack == null || pack.hidden == hidden) return;
    try {
      await _store?.setHidden(id, hidden);
    } catch (_) {
      // As above: the list is right now, storage catches up later.
    }
    state = state.copyWith(
      packs: [
        for (final existing in state.packs)
          if (existing.id == id)
            existing.copyWith(hidden: hidden)
          else
            existing,
      ],
    );
  }

  /// Deletes an imported voice: its files, its row, and its name.
  ///
  /// Bundled voices are refused: their MP3s are read-only inside the APK, so
  /// pretending to delete them would leave a voice the list says is gone.
  Future<void> delete(VoicePack pack) async {
    if (pack.builtIn) return;
    await _files.delete(pack.root);
    try {
      await _store?.delete(pack.id);
    } catch (_) {
      // The files are gone; a stale row is corrected on the next refresh.
    }
    state = state.copyWith(
      packs: [
        for (final existing in state.packs)
          if (existing.id != pack.id) existing,
      ],
    );
  }

  /// Opens the system file picker for a voice zip.
  Future<String?> pickZip() => _channel.pickZip();

  /// The name to offer for an import: the zip's own name, tidied up.
  String suggestName(String zipPath) {
    final file = zipPath.replaceAll('\\', '/').split('/').last;
    final base = file.toLowerCase().endsWith('.zip')
        ? file.substring(0, file.length - 4)
        : file;
    return VoicePackCatalogue.displayNameFor(base);
  }

  /// Unpacks [zipPath] into app storage under [name].
  ///
  /// The returned pack is already in [state]. Throws [VoiceImportException] with
  /// a readable reason when the archive holds nothing usable.
  Future<VoicePack> importZip({
    required String zipPath,
    required String name,
  }) async {
    final directory = await _channel.directory();
    if (directory == null) {
      throw const VoiceImportException(
        'This build has no place to keep an imported voice.',
      );
    }
    final label = name.trim().isEmpty ? suggestName(zipPath) : name.trim();
    final id = VoiceImport.uniqueId(
      VoiceImport.slugForName(label),
      state.packs.map((pack) => pack.id),
    );

    try {
      final pack = await _files.install(
        zipPath: zipPath,
        directory: directory,
        packId: id,
        name: label,
      );
      try {
        await _store?.save(pack);
      } catch (_) {
        // The voice works for this session; the row is rewritten next launch.
      }
      state = state.copyWith(packs: [...state.packs, pack]);
      return pack;
    } finally {
      await _files.discardCopy(zipPath);
    }
  }

  /// Bundled voices first, in the order the build lists them; then imported
  /// ones. A stored row overrides only the label and the hidden flag: the files
  /// on disk always decide what a bundled voice can actually read.
  static List<VoicePack> _merge(
    List<VoicePack> bundled,
    List<VoicePack> stored,
  ) {
    final overrides = {for (final pack in stored) pack.id: pack};
    final merged = [
      for (final pack in bundled)
        if (overrides[pack.id] case final row?)
          pack.copyWith(name: row.name, hidden: row.hidden)
        else
          pack,
    ];
    for (final pack in stored) {
      if (pack.builtIn) continue;
      merged.add(pack);
    }
    return merged;
  }
}

final voicePacksProvider =
    NotifierProvider<VoicePacksController, VoicePacksState>(
      VoicePacksController.new,
    );
