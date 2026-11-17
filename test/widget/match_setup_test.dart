import 'package:avalon_companion/app/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 3 gate: the MC can create a valid match for every supported table
/// size, and the session survives leaving the dashboard.
void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: AvalonApp()));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  }

  bool continueEnabled(WidgetTester tester) {
    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byKey(const Key('setup_continue')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    return semantics.properties.enabled ?? false;
  }

  testWidgets('every table size from 5 to 10 is a valid setup', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();

    for (var count = 5; count <= 10; count++) {
      await tester.tap(find.byKey(Key('setup_count_$count')));
      await tester.pumpAndSettle();

      for (var seat = 0; seat < count; seat++) {
        await tester.enterText(
          find.byKey(Key('setup_name_$seat')),
          'Player ${seat + 1}',
        );
      }
      await tester.pumpAndSettle();

      expect(
        continueEnabled(tester),
        isTrue,
        reason: '$count players with distinct names should be startable',
      );
      expect(find.text('Two players share the same name.'), findsNothing);
    }
  });

  testWidgets('a created match reaches the dashboard and can be continued', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setup_count_7')));
    await tester.pumpAndSettle();
    for (var seat = 0; seat < 7; seat++) {
      await tester.enterText(
        find.byKey(Key('setup_name_$seat')),
        'Player ${seat + 1}',
      );
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setup_continue')));
    await tester.pumpAndSettle();
    expect(find.text('PREPARATION'), findsOneWidget);
    expect(find.text('7 players are seated.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('preparation_begin')));
    await tester.pumpAndSettle();
    expect(find.text('THE ROUND TABLE'), findsWidgets);
    expect(find.text('7 seated'), findsOneWidget);
    expect(find.text('Player 7'), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'the dashboard must lay out without overflow at 360 dp',
    );

    // Leave the dashboard: the match stays live.
    await tester.tap(find.byKey(const Key('dashboard_home')));
    await tester.pumpAndSettle();
    expect(find.text('Leave the match?'), findsOneWidget);
    await tester.tap(find.text('Leave match'));
    await tester.pumpAndSettle();
    expect(find.text('MATCH IN PROGRESS'), findsOneWidget);
    expect(find.text('7 players · Quest 1 of 5'), findsOneWidget);

    final continueButton = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byKey(const Key('home_continue_game')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(continueButton.properties.enabled, isTrue);

    await tester.tap(find.byKey(const Key('home_continue_game')));
    await tester.pumpAndSettle();
    expect(find.text('THE ROUND TABLE'), findsWidgets);
  });

  testWidgets('aborting a match clears the session', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();
    for (var seat = 0; seat < 5; seat++) {
      await tester.enterText(
        find.byKey(Key('setup_name_$seat')),
        'Player ${seat + 1}',
      );
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setup_continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preparation_begin')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard_abort')));
    await tester.pumpAndSettle();
    expect(find.text('Abort the match?'), findsOneWidget);

    await tester.tap(find.text('Abort match'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_new_game')), findsOneWidget);
    expect(find.text('No match in progress.'), findsOneWidget);
  });

  testWidgets('preparation can be abandoned without creating a match', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();
    for (var seat = 0; seat < 5; seat++) {
      await tester.enterText(
        find.byKey(Key('setup_name_$seat')),
        'Player ${seat + 1}',
      );
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setup_continue')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('GAME SETUP'), findsOneWidget);
    expect(find.byKey(const Key('setup_continue')), findsOneWidget);
  });
}
