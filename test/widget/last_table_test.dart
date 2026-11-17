import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/database/database_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_match_store.dart';

/// Setup remembers the seats, not the roles: **Use the last table** restores the
/// count and the names, and the MC can still edit every field.
void main() {
  Future<void> openSetup(WidgetTester tester, FakeMatchStore store) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [matchStoreProvider.overrideWithValue(store)],
        child: const AvalonApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();
  }

  String nameAt(WidgetTester tester, int seat) => tester
      .widget<TextField>(find.byKey(Key('setup_name_$seat')))
      .controller!
      .text;

  testWidgets('the last table fills the count and the names', (tester) async {
    final store = FakeMatchStore()
      ..lastRosterNames = const [
        'Ann',
        'Ben',
        'Cara',
        'Dev',
        'Eli',
        'Fay',
        'Gus',
      ];
    await openSetup(tester, store);

    expect(find.byKey(const Key('setup_use_last_table')), findsOneWidget);
    expect(find.text('Use the last table · 7 players'), findsOneWidget);

    await tester.tap(find.byKey(const Key('setup_use_last_table')));
    await tester.pumpAndSettle();

    for (var seat = 0; seat < 7; seat++) {
      expect(nameAt(tester, seat), store.lastRosterNames[seat]);
    }
    expect(find.byKey(const Key('setup_name_7')), findsNothing);
    expect(find.textContaining('7 players — 4 good, 3 evil.'), findsOneWidget);

    // The fields stay editable after the restore.
    await tester.enterText(find.byKey(const Key('setup_name_0')), 'Anton');
    await tester.pump();
    expect(nameAt(tester, 0), 'Anton');
  });

  testWidgets('with no stored table the chip is not offered', (tester) async {
    await openSetup(tester, FakeMatchStore());

    expect(find.byKey(const Key('setup_use_last_table')), findsNothing);
  });
}
