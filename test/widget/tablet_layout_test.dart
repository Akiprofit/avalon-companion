import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/core/constants/routes.dart';
import 'package:avalon_companion/core/widgets/avalon_bottom_navigation.dart';
import 'package:avalon_companion/core/widgets/avalon_screen.dart';
import 'package:avalon_companion/core/widgets/narration_panel.dart';
import 'package:avalon_companion/core/widgets/primary_button.dart';
import 'package:avalon_companion/game_engine/controllers/game_session_controller.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Tablet gate: the layout is the phone layout, centred in one readable
/// column. These tests render the real screens at tablet sizes and prove the
/// column never stretches across the glass, and never overflows either.
void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Size logical = const Size(800, 1280),
    double dpr = 2.0,
  }) async {
    tester.view.physicalSize = logical * dpr;
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: AvalonApp()));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  }

  GoRouter routerOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
          as GoRouter;

  /// Gutter on each side of the content column. A centred column has equal
  /// gutters; a phone, where the column fills the width, has none.
  ({double left, double right, double width, double height}) column(
    WidgetTester tester,
  ) {
    final size = tester.getSize(find.byKey(AvalonScreen.contentKey));
    final origin = tester.getTopLeft(find.byKey(AvalonScreen.contentKey));
    final screen =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    return (
      left: origin.dx,
      right: screen - origin.dx - size.width,
      width: size.width,
      height: size.height,
    );
  }

  void expectTabletColumn(WidgetTester tester) {
    final c = column(tester);
    expect(
      c.width,
      lessThanOrEqualTo(AvalonScreen.maxContentWidth),
      reason: 'the column must not stretch across the tablet',
    );
    expect(c.width, greaterThan(300), reason: 'the column is not collapsed');
    expect(
      c.left,
      closeTo(c.right, 1),
      reason: 'the column sits in the middle of the glass',
    );
    expect(
      c.height,
      greaterThan(300),
      reason: 'the bar must not eat the body behind it',
    );
  }

  testWidgets('a phone keeps the full-width layout it had', (tester) async {
    await pumpApp(tester, logical: const Size(360, 780), dpr: 3.0);

    final c = column(tester);
    expect(c.width, 360, reason: 'no inset on a phone');
    expect(c.left, 0);
  });

  testWidgets('the tablet navigation band stays a bar and still taps', (
    tester,
  ) async {
    await pumpApp(tester);

    final band = tester.getSize(find.byType(AvalonBottomNavigation));
    expect(
      band.height,
      lessThan(140),
      reason: 'the band is not a full-height overlay swallowing taps',
    );

    await tester.tap(find.byKey(const Key('nav_history')));
    await tester.pumpAndSettle();
    expect(find.text('GAME HISTORY'), findsOneWidget);
  });

  testWidgets('every reading screen centres one column on a portrait tablet', (
    tester,
  ) async {
    await pumpApp(tester);

    final router = routerOf(tester);
    for (final route in [
      RouteNames.home,
      RouteNames.settings,
      RouteNames.history,
      RouteNames.setup,
      RouteNames.howToPlay,
    ]) {
      router.goNamed(route);
      await tester.pumpAndSettle();
      expectTabletColumn(tester);
      expect(tester.takeException(), isNull, reason: '$route overflows');
    }
  });

  testWidgets('a drag on the tablet gutter scrolls the page', (tester) async {
    await pumpApp(tester, logical: const Size(1280, 800));

    routerOf(tester).goNamed(RouteNames.howToPlay);
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(scrollable.position.pixels, 0, reason: 'the page starts at the top');

    final gutter = column(tester).left;
    expect(
      gutter,
      greaterThan(100),
      reason: 'a landscape tablet has glass beside the reading column',
    );

    // The finger lands on the background, not on the list.
    await tester.dragFrom(Offset(gutter / 2, 500), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(
      scrollable.position.pixels,
      greaterThan(0),
      reason: 'the side of the screen scrolls the page',
    );
  });

  testWidgets('a ten-player dashboard keeps its action column on a landscape '
      'tablet', (tester) async {
    await pumpApp(tester, logical: const Size(1280, 800));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AvalonApp)),
    );
    final defaults = AvalonTables.defaultComposition(10);
    final counts = <Character, int>{
      for (final character in Character.values)
        if ((defaults[character.label] ?? 0) > 0)
          character: defaults[character.label]!,
    };
    container
        .read(gameSessionProvider.notifier)
        .start(
          names: [for (var seat = 1; seat <= 10; seat++) 'P$seat'],
          composition: Composition(playerCount: 10, counts: counts),
        );

    routerOf(tester).goNamed(RouteNames.dashboard);
    await tester.pumpAndSettle();

    expectTabletColumn(tester);
    final button = tester.getSize(find.byType(PrimaryButton).first);
    expect(
      button.width,
      lessThanOrEqualTo(AvalonScreen.maxContentWidth),
      reason: 'the gold action is a button, not a full-width band',
    );
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets(
      'the night panel still fits a landscape tablet at ${scale}x text',
      (tester) async {
        tester.view.physicalSize = const Size(2560, 1600);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          MaterialApp(
            home: AvalonScreen(
              backgroundDecoration: false,
              child: NarrationPanel(
                heading: 'The night begins',
                text:
                    'Everyone closes their eyes. Breathe slowly and keep your '
                    'hands still on the table.',
                nextLine: 'Minions of Mordred, open your eyes.',
                englishLabel: 'English',
                filipinoLabel: 'Filipino',
                languageIsFilipino: false,
                position: 1,
                total: 14,
                isAutoPlaying: true,
                canGoBack: false,
                canGoForward: true,
                onPrevious: () {},
                onNext: () {},
                onReplay: () {},
                onToggleAutoPlay: () {},
                onLanguageChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expectTabletColumn(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
