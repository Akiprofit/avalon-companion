import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/app/bootstrap.dart';
import 'package:avalon_companion/database/database_provider.dart';
import 'package:avalon_companion/game_engine/controllers/game_session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// Phase 11 device gate. These run the real app on the phone — the real SQLite
/// file, the real settings store, the real platform channels — rather than a
/// widget tree over fakes.
///
///   flutter test integration_test -d DEVICE_ID
///
/// They are deliberately short: the point is that the shipped wiring works and
/// that the installed database still has no place to store a character.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(AvalonApp)));

  /// Advance the real app by a couple of seconds of frames.
  ///
  /// `pumpAndSettle` waits for every animation on screen to finish, and each
  /// screen's background plate drifts for twenty-four seconds, so on a phone it
  /// turns every step into half a minute. Route transitions and the splash timer
  /// are over inside two seconds; the drift is decoration and does not need to
  /// be waited for.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// The columns of a table in the live database.
  Future<List<String>> columnsOf(
    WidgetTester tester,
    String table,
  ) async {
    final database = containerOf(tester).read(appDatabaseProvider);
    expect(database, isNotNull, reason: 'the database must open on device');
    final rows = await database!
        .customSelect("SELECT name FROM pragma_table_info('$table')")
        .get();
    return [for (final row in rows) row.read<String>('name').toLowerCase()];
  }

  testWidgets('the team approval vote round-trips through the real store', (
    tester,
  ) async {
    await bootstrap();
    await settle(tester);

    // Home scrolls and its own Settings tile sits under the bottom bar, so use
    // the shell's navigation instead of scrolling to a tile that is covered.
    await tester.tap(find.byKey(const Key('nav_settings')));
    await settle(tester);

    expect(
      find.text('SETTINGS'),
      findsOneWidget,
      reason: 'the settings screen opened; a PIN-locked screen is not testable',
    );

    // Settings is a lazy ListView: the game section is below the fold, so its
    // tile does not exist until the list is scrolled to it.
    final tile = find.byKey(const Key('settings_team_vote'));
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    await settle(tester);

    final toggle = find.descendant(of: tile, matching: find.byType(Switch));
    await tester.ensureVisible(toggle);
    await settle(tester);

    /// The stored switch, or the schema default when the row has not been
    /// written yet — a fresh install has no settings row until the first change.
    Future<int> stored() async {
      final database = containerOf(tester).read(appDatabaseProvider);
      final row = await database!
          .customSelect('SELECT team_vote_enabled FROM settings LIMIT 1')
          .getSingleOrNull();
      return row?.read<int>('team_vote_enabled') ?? 1;
    }

    final before = await stored();
    await tester.tap(toggle);
    await settle(tester);
    expect(await stored(), before == 1 ? 0 : 1,
        reason: 'the switch writes to the installed database');

    // Put the device back the way it was found.
    await tester.tap(toggle);
    await settle(tester);
    expect(await stored(), before);
  });

  testWidgets('a match starts on the real database and stores no characters', (
    tester,
  ) async {
    await bootstrap();
    await settle(tester);

    await tester.tap(find.byKey(const Key('home_new_game')));
    await settle(tester);

    for (var seat = 0; seat < 5; seat++) {
      await tester.enterText(
        find.byKey(Key('setup_name_$seat')),
        'Device ${seat + 1}',
      );
    }
    await settle(tester);
    await tester.tap(find.byKey(const Key('setup_continue')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('preparation_begin')));
    await settle(tester);

    expect(
      find.byKey(const Key('dashboard_open_narration')),
      findsOneWidget,
      reason: 'the match reaches the round table',
    );

    // The privacy rule, checked against the database the app is writing to.
    const forbidden = [
      'character',
      'role',
      'allegiance',
      'merlin',
      'morgana',
      'percival',
    ];
    for (final table in [
      'games',
      'players',
      'quests',
      'team_proposals',
      'game_events',
      'settings',
    ]) {
      final columns = await columnsOf(tester, table);
      expect(columns, isNotEmpty, reason: '$table exists in the live database');
      for (final column in columns) {
        final tokens = column.split('_');
        for (final word in forbidden) {
          expect(
            tokens.any((token) => token == word || token == '${word}s'),
            isFalse,
            reason: '$table.$column stores a character or an allegiance',
          );
        }
      }
    }

    // The roster is a seat and a name only, which is what the players table holds.
    expect(
      await columnsOf(tester, 'players'),
      containsAll(<String>['game_id', 'display_name', 'seat_number']),
    );

    final game = containerOf(tester).read(gameSessionProvider);
    expect(game?.players.map((p) => p.name), [
      'Device 1',
      'Device 2',
      'Device 3',
      'Device 4',
      'Device 5',
    ]);
  });
}
