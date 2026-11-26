import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:avalon_companion/database/app_database.dart';
import 'package:avalon_companion/database/repositories/voice_pack_repository.dart';
import 'package:avalon_companion/narration_engine/models/narration_instruction.dart';
import 'package:avalon_companion/narration_engine/models/voice_pack.dart';
import 'package:avalon_companion/narration_engine/services/narration_clips.dart';
import 'package:avalon_companion/narration_engine/services/voice_files.dart';
import 'package:avalon_companion/narration_engine/services/voice_import.dart';
import 'package:avalon_companion/narration_engine/services/voice_pack_catalogue.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Narrator voices are packs, not files, and they are the one part of the app
/// the MC can replace. These tests pin down what a pack is, how a zip becomes
/// one, and that a voice choice survives an app upgrade.
void main() {
  List<int> zipOf(Map<String, List<int>> files) {
    final archive = Archive();
    for (final entry in files.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    return ZipEncoder().encode(archive)!;
  }

  VoicePack pack({
    String id = 'dahlia',
    String name = 'Voice of Dahlia',
    Map<String, Set<String>> clips = const {'en': {'night.end'}},
    bool builtIn = false,
    bool hidden = false,
  }) {
    return VoicePack(
      id: id,
      name: name,
      root: '/storage/voices/$id',
      clips: clips,
      builtIn: builtIn,
      hidden: hidden,
    );
  }

  group('the catalogue', () {
    test('finds the shipped narrator and every bundled voice folder', () {
      final packs = VoicePackCatalogue.fromAssets(const [
        'assets/audio/narration/Dahlia voices/en/night.close_eyes.mp3',
        'assets/audio/narration/Dahlia voices/fil/night.close_eyes.mp3',
        'assets/audio/voices/voice-of-dahlia/en/night.close_eyes.mp3',
        'assets/audio/voices/voice-of-dahlia/fil/night.close_eyes.mp3',
        'assets/audio/voices/voice-of-dahlia/en/notes.txt',
        'assets/audio/voices/README.md',
      ]);

      expect(packs.map((pack) => pack.id), ['classic', 'voice-of-dahlia']);
      expect(packs.first.name, VoicePackCatalogue.classicName);
      expect(packs.first.builtIn, isTrue);
      expect(packs.last.name, 'Voice of Dahlia');
      expect(
        packs.last.pathFor('night.close_eyes', NarrationLanguage.filipino),
        'assets/audio/voices/voice-of-dahlia/fil/night.close_eyes.mp3',
      );
    });

    test('only counts recordings under a language folder', () {
      final packs = VoicePackCatalogue.fromAssets(const [
        'assets/audio/narration/Dahlia voices/en/night.end.mp3',
        'assets/audio/voices/dahlia/night.end.mp3',
        'assets/audio/voices/dahlia/en/README.md',
        'assets/audio/voices/dahlia/en/._night.end.mp3',
        'assets/audio/voices/dahlia/de/night.end.mp3',
      ]);

      expect(packs.map((pack) => pack.id), ['classic']);
    });

    test('a capitalised folder name is still a voice', () {
      final packs = VoicePackCatalogue.fromAssets(const [
        'assets/audio/narration/Dahlia voices/en/night.end.mp3',
        'assets/audio/voices/Grok/en/night.end.mp3',
        'assets/audio/voices/Grok/fil/night.end.mp3',
      ]);

      expect(packs.map((pack) => pack.id), ['classic', 'Grok']);
      final grok = packs.last;
      expect(grok.name, 'Grok');
      expect(grok.hasClip('night.end', NarrationLanguage.filipino), isTrue);
      expect(
        grok.pathFor('night.end', NarrationLanguage.english),
        'assets/audio/voices/Grok/en/night.end.mp3',
      );
    });

    test('a pack missing a language falls back for that language only', () {      final packs = VoicePackCatalogue.fromAssets(const [
        'assets/audio/narration/Dahlia voices/en/night.end.mp3',
        'assets/audio/voices/dahlia/en/night.end.mp3',
      ]);
      final dahlia = packs.last;

      expect(dahlia.hasClip('night.end', NarrationLanguage.english), isTrue);
      expect(dahlia.hasClip('night.end', NarrationLanguage.filipino), isFalse);
      expect(
        dahlia.pathFor('night.end', NarrationLanguage.filipino),
        isNull,
        reason: 'the night falls back to the phone voice for that line',
      );
    });

    test('a build without shipped recordings still behaves like today', () {
      final packs = VoicePackCatalogue.fromAssets(const []);

      expect(packs, hasLength(1));
      expect(packs.single.id, VoicePackCatalogue.classicId);
      for (final id in NarrationClips.ids) {
        expect(packs.single.hasClip(id, NarrationLanguage.english), isTrue);
      }
    });

    test('folder names become readable voice names', () {
      expect(
        VoicePackCatalogue.displayNameFor('voice-of-dahlia'),
        'Voice of Dahlia',
      );
      expect(VoicePackCatalogue.displayNameFor('dahlia'), 'Dahlia');
      expect(VoicePackCatalogue.displayNameFor('marc_s_deep'), 'Marc S Deep');
    });

    test('a voice may name itself in voice.json', () {
      expect(
        VoicePackCatalogue.nameFromJson('{"name":"Voice of Dahlia"}'),
        'Voice of Dahlia',
      );
      expect(VoicePackCatalogue.nameFromJson('{"name":"   "}'), isNull);
      expect(VoicePackCatalogue.nameFromJson('not json'), isNull);
      expect(VoicePackCatalogue.nameFromJson('{"other":1}'), isNull);
    });
  });

  group('importing a zip', () {
    test('keeps the narration and ignores everything else', () {
      final clips = VoiceImport.clipsFromZip(
        zipOf({
          'Voice of Dahlia/en/night.close_eyes.mp3': [1, 2, 3],
          'Voice of Dahlia/fil/night.close_eyes.mp3': [4, 5, 6],
          'Voice of Dahlia/en/notes.txt': [7],
          '__MACOSX/Voice of Dahlia/en/._night.close_eyes.mp3': [8],
          'Voice of Dahlia/de/night.close_eyes.mp3': [9],
        }),
      );

      expect(clips.keys, {'en', 'fil'});
      expect(clips['en']!.keys, {'night.close_eyes'});
      expect(clips['fil']!.keys, {'night.close_eyes'});
      expect(clips['en']!['night.close_eyes'], [1, 2, 3]);
    });

    test('reads a flat zip as English', () {
      final clips = VoiceImport.clipsFromZip(
        zipOf({'night.end.mp3': [1, 2], 'night.close_eyes.mp3': [3, 4]}),
      );
      expect(clips.keys, {'en'});
      expect(clips['en']!.keys, {'night.end', 'night.close_eyes'});
    });

    test('refuses a zip with no narration in it', () {
      expect(
        () => VoiceImport.clipsFromZip(
          zipOf({
            'notes.txt': utf8.encode('no audio here'),
          }),
        ),
        throwsA(isA<VoiceImportException>()),
      );
    });

    test('refuses a file that is not a zip', () {
      expect(
        () => VoiceImport.clipsFromZip(utf8.encode('this is not a zip')),
        throwsA(isA<VoiceImportException>()),
      );
    });

    test('a folder name can never climb out of the voices directory', () {
      expect(VoiceImport.slugForName('../../etc/passwd'), 'etc-passwd');
      expect(VoiceImport.slugForName('Voice of Dahlia'), 'voice-of-dahlia');
      expect(
        VoicePackCatalogue.isValidId('../escape'),
        isFalse,
        reason: 'ids are matched against a whitelist before any file is read',
      );
    });

    test('two voices with the same name get different folders', () {
      expect(VoiceImport.uniqueId('dahlia', ['classic']), 'dahlia');
      expect(VoiceImport.uniqueId('dahlia', ['dahlia']), 'dahlia-2');
      expect(
        VoiceImport.uniqueId('dahlia', ['dahlia', 'dahlia-2']),
        'dahlia-3',
      );
    });

    test('an imported zip lands in the voices folder and deletes cleanly',
        () async {
      final directory = await Directory.systemTemp.createTemp('avalon_voices');
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });

      final zip = File('${directory.path}/Voice of Dahlia.zip');
      await zip.writeAsBytes(
        zipOf({
          'Voice of Dahlia/en/night.close_eyes.mp3': [1, 2, 3],
          'Voice of Dahlia/fil/night.close_eyes.mp3': [4, 5, 6],
        }),
      );

      const files = VoiceFiles();
      final pack = await files.install(
        zipPath: zip.path,
        directory: '${directory.path}/voices',
        packId: 'voice-of-dahlia',
        name: 'Voice of Dahlia',
      );

      expect(pack.name, 'Voice of Dahlia');
      expect(pack.builtIn, isFalse);
      expect(pack.hasClip('night.close_eyes', NarrationLanguage.english), isTrue);
      final written = File('${pack.root}/en/night.close_eyes.mp3');
      expect(await written.readAsBytes(), [1, 2, 3]);

      await files.delete(pack.root);
      expect(
        await Directory(pack.root).exists(),
        isFalse,
        reason: 'deleting a voice removes its recordings, not just its row',
      );
    });
  });

  group('storage', () {
    test('a voice round-trips through the stored row', () {
      final companion = VoicePackRepository.encode(
        pack(clips: const {
          'en': {'night.end', 'night.close_eyes'},
          'fil': {'night.end'},
        }),
      );

      expect(companion.id.value, 'dahlia');
      expect(companion.name.value, 'Voice of Dahlia');
      expect(companion.builtIn.value, isFalse);

      final decoded = VoicePackRepository.decode(
        VoicePackRecord(
          id: 'dahlia',
          name: 'Voice of Dahlia',
          clips: companion.clips.value,
          builtIn: false,
          hidden: false,
          root: '/storage/voices/dahlia',
          createdAt: 0,
        ),
      );

      expect(decoded.clips['en'], {'night.close_eyes', 'night.end'});
      expect(decoded.clips['fil'], {'night.end'});
      expect(
        decoded.pathFor('night.close_eyes', NarrationLanguage.english),
        '/storage/voices/dahlia/en/night.close_eyes.mp3',
      );
    });

    test('a corrupt or empty clip map is read as "no recordings"', () {
      expect(VoicePackRepository.decodeClips(''), isEmpty);
      expect(VoicePackRepository.decodeClips('nope'), isEmpty);
      expect(VoicePackRepository.decodeClips('[]'), isEmpty);
      expect(VoicePackRepository.decodeClips('{"en":[1,2]}'), isEmpty);
    });

    test('a version 6 database gains the voice table and keeps the choice',
        () async {
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'avalon_voices_migration.db',
      );
      if (await file.exists()) await file.delete();

      final before = AppDatabase(NativeDatabase(file));
      await before.into(before.voicePacks).insert(
        VoicePackRepository.encode(pack(name: 'Voice of Dahlia')),
      );
      await before.close();

      // Wind the file back to v6: no table, no chosen-voice column, no v8
      // Big table switch, and no v9 Table Mode role.
      sqlite3.open(file.path)
        ..execute('DROP TABLE voice_packs')
        ..execute('ALTER TABLE settings DROP COLUMN voice_pack_id')
        ..execute('ALTER TABLE settings DROP COLUMN big_table_enabled')
        ..execute('ALTER TABLE settings DROP COLUMN table_role')
        ..execute('PRAGMA user_version = 6')
        ..close();

      final after = AppDatabase(NativeDatabase(file));
      addTearDown(() async {
        await after.close();
        if (await file.exists()) await file.delete();
      });

      final voices = await VoicePackRepository(after).loadAll();
      expect(
        voices,
        isEmpty,
        reason: 'the table exists, and starts empty — bundled voices are seeded',
      );

      await VoicePackRepository(after).save(pack(name: 'Voice of Dahlia'));
      final saved = await VoicePackRepository(after).loadAll();
      expect(saved.single.name, 'Voice of Dahlia');
    });

    test('renaming and hiding keep the folder untouched', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = VoicePackRepository(db);
      await store.save(pack());

      await store.rename('dahlia', 'Voice of Dahlia at the pub');
      await store.setHidden('dahlia', true);

      final voices = await store.loadAll();
      expect(voices.single.name, 'Voice of Dahlia at the pub');
      expect(voices.single.hidden, isTrue);
      expect(voices.single.id, 'dahlia');
      expect(voices.single.root, '/storage/voices/dahlia');
    });
  });

  test('every bundled voice folder is listed in pubspec', () {
    // Flutter asset folders are not recursive. A voice folder that is on disk
    // but not listed is invisible to the app: no line plays and the picker
    // never shows it. This is the guard the shipped narrator already has.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final voices = Directory(
      VoicePackCatalogue.assetDirectory,
    ).listSync().whereType<Directory>();

    expect(voices, isNotEmpty, reason: 'Okley ships inside the APK');
    for (final voice in voices) {
      final root = voice.path.replaceAll(r'\', '/');
      for (final language in ['en', 'fil']) {
        if (!Directory('$root/$language').existsSync()) continue;
        expect(
          pubspec.contains('$root/$language/'),
          isTrue,
          reason: 'pubspec.yaml must list $root/$language/',
        );
      }
    }
  });

  test('the bundled Okley voice has both languages and a name', () {
    final assets = [
      // One shipped line, so the catalogue also builds the classic pack.
      NarrationClips.assetFor('night.end', NarrationLanguage.english),
      for (final language in ['en', 'fil'])
        for (final file in Directory(
          '${VoicePackCatalogue.assetDirectory}/okley/$language',
        ).listSync().whereType<File>())
          '${VoicePackCatalogue.assetDirectory}/okley/$language/'
              '${file.uri.pathSegments.last}',
    ];
    final pack = VoicePackCatalogue.fromAssets(
      assets,
    ).singleWhere((pack) => pack.id == 'okley');

    expect(pack.name, 'Okley');
    for (final language in NarrationLanguage.values) {
      expect(
        pack.clips[NarrationClips.folderFor(language)],
        containsAll(NarrationClips.ids),
        reason: 'a complete set, so no line falls back to the phone — extra '
            'recordings for round lines are allowed and simply unused',
      );
    }
  });
}
