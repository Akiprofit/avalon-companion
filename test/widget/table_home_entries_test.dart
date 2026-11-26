import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/core/constants/routes.dart';
import 'package:avalon_companion/core/models/table_role.dart';
import 'package:avalon_companion/database/database_provider.dart';
import 'package:avalon_companion/features/settings/settings_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Home offers the right Table Mode door for this device, and Settings is where
/// the device says which door that is.
///
/// The rule is a support rule: a board that shows "Join a Game" gets tapped, and
/// a phone that shows "Tablet Mode" tries to host a room it cannot host.
void main() {
  const hostEntry = Key('home_table_host');
  const joinEntry = Key('home_join');

  /// Boots the app on a phone-sized screen with [role] already remembered.
  Future<ProviderContainer> pumpHome(
    WidgetTester tester, {
    TableRole role = TableRole.solo,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSettingsProvider.overrideWithValue(
            AppSettings(tableRole: role),
          ),
        ],
        child: const AvalonApp(),
      ),
    );
    await tester.pumpAndSettle();
    // Splash holds for 1.4s then hands over to Home.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    return ProviderScope.containerOf(tester.element(find.byType(AvalonApp)));
  }

  GoRouter routerOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
          as GoRouter;

  testWidgets('a solo device is offered both doors', (tester) async {
    await pumpHome(tester);

    expect(find.byKey(hostEntry), findsOneWidget);
    expect(find.byKey(joinEntry), findsOneWidget);
  });

  testWidgets('the board never offers "Join a Game"', (tester) async {
    await pumpHome(tester, role: TableRole.board);

    expect(find.byKey(hostEntry), findsOneWidget);
    expect(
      find.byKey(joinEntry),
      findsNothing,
      reason: 'a board does not take a seat, so it must not offer one',
    );
  });

  testWidgets('a player phone never offers "Tablet Mode"', (tester) async {
    await pumpHome(tester, role: TableRole.player);

    expect(find.byKey(joinEntry), findsOneWidget);
    expect(
      find.byKey(hostEntry),
      findsNothing,
      reason: 'a phone that hosts would need a room the table is not on',
    );
  });

  testWidgets('choosing the role in Settings changes Home at once', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    final router = routerOf(tester);

    router.goNamed(RouteNames.settings);
    await tester.pumpAndSettle();

    final boardChip = find.byKey(const Key('settings_table_role_board'));
    await tester.scrollUntilVisible(
      boardChip,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(boardChip);
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).tableRole, TableRole.board);
    expect(
      find.textContaining('Home shows Tablet Mode only'),
      findsOneWidget,
      reason: 'the choice explains itself where it is made',
    );

    router.goNamed(RouteNames.home);
    await tester.pumpAndSettle();

    expect(find.byKey(hostEntry), findsOneWidget);
    expect(find.byKey(joinEntry), findsNothing);
  });
}
