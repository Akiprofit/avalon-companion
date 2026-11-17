import 'package:avalon_companion/app/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The night screen keeps the one control that ends the night away from Next:
/// it is a labelled app-bar action behind a confirmation, and the language
/// switch lives at the top instead of under the transport.
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

  /// Five-player match, prepared, with the night narration open.
  Future<void> openNight(WidgetTester tester) async {
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

    await tester.tap(find.byKey(const Key('dashboard_open_narration')));
    await tester.pumpAndSettle();
  }

  testWidgets('stop is gone from the transport and the language sits on top', (
    tester,
  ) async {
    await openNight(tester);

    expect(find.byKey(const Key('narration_stop')), findsNothing);
    expect(find.byKey(const Key('narration_next')), findsOneWidget);
    expect(find.byKey(const Key('narration_language')), findsOneWidget);

    final language = tester.getCenter(
      find.byKey(const Key('narration_language')),
    );
    final end = tester.getCenter(find.byKey(const Key('narration_end')));
    final next = tester.getCenter(find.byKey(const Key('narration_next')));

    expect(end.dy, lessThan(language.dy), reason: 'End night is in the bar');
    expect(
      language.dy,
      lessThan(next.dy),
      reason: 'language is above the transport',
    );
    expect(
      find.text('THE NIGHT'),
      findsOneWidget,
      reason: 'the shorter title fits beside the End night action',
    );
  });

  testWidgets('ending the night asks first, then opens the draw', (
    tester,
  ) async {
    await openNight(tester);

    await tester.tap(find.byKey(const Key('narration_end')));
    await tester.pumpAndSettle();
    expect(find.text('End the night?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('narration_next')), findsOneWidget);
    expect(find.text('CHOOSE THE LORD'), findsNothing);

    await tester.tap(find.byKey(const Key('narration_end')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End the night'));
    await tester.pumpAndSettle();

    expect(find.text('CHOOSE THE LORD'), findsWidgets);
  });
}
