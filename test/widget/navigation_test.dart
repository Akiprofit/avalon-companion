import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/core/constants/routes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: AvalonApp()));
    await tester.pumpAndSettle();
    // Splash holds for 1.4s then hands over to Home.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  }

  testWidgets('splash leads to the home screen', (tester) async {
    await pumpApp(tester);
    expect(find.text('AVALON'), findsOneWidget);
    expect(find.text('COMPANION'), findsOneWidget);
    expect(find.byKey(const Key('home_new_game')), findsOneWidget);
  });

  testWidgets('home reaches setup and back', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();

    expect(find.text('GAME SETUP'), findsOneWidget);
    expect(find.byKey(const Key('setup_continue')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_new_game')), findsOneWidget);
  });

  testWidgets('setup cannot continue until the roster and names are valid', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('home_new_game')));
    await tester.pumpAndSettle();

    final continueFinder = find.byKey(const Key('setup_continue'));
    expect(continueFinder, findsOneWidget);

    // Names are empty, so the screen must not allow the next step.
    final button = tester.widget<Semantics>(
      find.descendant(of: continueFinder, matching: find.byType(Semantics)).first,
    );
    expect(button.properties.enabled, isFalse);
  });

  testWidgets('home reaches settings, history and how to play', (tester) async {
    await pumpApp(tester);
    final router = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .routerConfig! as GoRouter;

    router.goNamed(RouteNames.settings);
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS'), findsOneWidget);

    router.goNamed(RouteNames.history);
    await tester.pumpAndSettle();
    expect(find.text('GAME HISTORY'), findsOneWidget);

    router.goNamed(RouteNames.howToPlay);
    await tester.pumpAndSettle();
    expect(find.text('HOW TO PLAY'), findsOneWidget);
  });

  testWidgets('dashboard is unreachable without a live match', (tester) async {
    await pumpApp(tester);
    final router = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .routerConfig! as GoRouter;

    router.goNamed(RouteNames.dashboard);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_new_game')), findsOneWidget);
  });

  testWidgets('small screen renders home without overflow', (tester) async {
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: AvalonApp()));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('home_new_game')), findsOneWidget);
  });
}
