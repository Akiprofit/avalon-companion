import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/core/constants/routes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The manual has to be playable at the table: real Avalon rules, in the order
/// a match happens, with the app's part marked clearly.
void main() {
  Future<GoRouter> pumpManual(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: AvalonApp()));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    final router =
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
            as GoRouter;
    router.goNamed(RouteNames.howToPlay);
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.dragUntilVisible(
      target,
      find.byType(ListView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the manual opens on the rules, not the app', (tester) async {
    await pumpManual(tester);

    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.text('BEFORE YOU BEGIN'), findsOneWidget);
    expect(find.textContaining('five to ten players'), findsOneWidget);
    expect(
      find.textContaining('never asks who holds which card'),
      findsOneWidget,
    );
  });

  testWidgets('setup, night order and the quest table are covered', (
    tester,
  ) async {
    await pumpManual(tester);

    await scrollTo(tester, find.text('SET UP THE TABLE'));
    expect(find.textContaining('Seat 1 is the first leader'), findsOneWidget);

    await scrollTo(tester, find.text('THE NIGHT'));
    expect(
      find.textContaining('Every evil player except Oberon'),
      findsOneWidget,
    );
    expect(
      find.textContaining('two candidates, and Percival never learns'),
      findsOneWidget,
    );

    await scrollTo(tester, find.text('TEAM SIZE'));
    expect(find.text('Q5'), findsOneWidget);
    // 5 players, quest 1: a two-seat team; quest 5: three seats.
    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('every rule the app enforces is stated', (tester) async {
    await pumpManual(tester);

    await scrollTo(tester, find.text('RULES THAT CATCH PEOPLE OUT'));
    expect(
      find.textContaining('Five rejected proposals in a row'),
      findsOneWidget,
    );
    expect(
      find.textContaining('two fail cards when seven or more'),
      findsOneWidget,
    );
    expect(find.textContaining('strict majority'), findsWidgets);

    await scrollTo(tester, find.text('THE FINAL ACCUSATION'));
    expect(find.textContaining('names one player as Merlin'), findsOneWidget);

    await scrollTo(tester, find.text('HOW TO WIN'));
    expect(
      find.textContaining('keeping Merlin alive through the accusation'),
      findsOneWidget,
    );
  });
}
