import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/app_settings.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../database/repositories/game_repository.dart';
import '../database/repositories/settings_repository.dart';
import 'app.dart';

/// Single entry point: open storage, then install the provider scope and run.
///
/// Opening SQLite, reading the saved preferences and looking for a match that
/// was still running all happen before the first frame, so the app never
/// flashes default settings or "no match in progress". Every step is optional:
/// if the database cannot be opened the app still runs, fully playable, and just
/// does not remember anything.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppDatabase? database;
  var initialSettings = const AppSettings();
  StoredMatch? restored;

  try {
    database = openAppDatabase();
    final repository = GameRepository(database);
    initialSettings = await SettingsRepository(database).load();
    restored = await repository.findInProgress();
  } catch (error, stack) {
    // Keep playing: a storage problem is reported in debug, never in the way.
    debugPrint('Avalon storage unavailable: $error');
    debugPrintStack(stackTrace: stack);
    await database?.close();
    database = null;
  }

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        initialSettingsProvider.overrideWithValue(initialSettings),
        restoredMatchProvider.overrideWithValue(restored),
      ],
      child: const AvalonApp(),
    ),
  );
}
