import 'package:avalon_companion/app/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 5 gate: the MC can take a match from the end of the night to a valid
/// quest team, and the discussion timer behaves like a clock.
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

  /// Creates a five-player match and leaves it at the dashboard, phase
  /// preparation.
  Future<void> startMatch(WidgetTester tester) async {
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
  }

  /// Opens the night, skips to the end and returns to the dashboard in Day.
  Future<void> reachDay(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('dashboard_open_narration')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('narration_stop')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('narration_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lord_spin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lord_continue')));
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, Key key) {
    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byKey(key),
            matching: find.byType(Semantics),
          )
          .first,
    );
    return semantics.properties.enabled ?? false;
  }

  testWidgets('the dashboard offers team selection after the night', (
    tester,
  ) async {
    await startMatch(tester);
    expect(find.byKey(const Key('dashboard_open_narration')), findsOneWidget);

    await reachDay(tester);

    expect(find.text('DAY'), findsWidgets);
    expect(find.byKey(const Key('dashboard_choose_team')), findsOneWidget);
    expect(find.byKey(const Key('discussion_time')), findsOneWidget);
    expect(find.text('5:00'), findsOneWidget);
  });

  testWidgets('the discussion timer runs and resets', (tester) async {
    await startMatch(tester);
    await reachDay(tester);

    await tester.tap(find.byKey(const Key('discussion_toggle')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('4:59'), findsOneWidget);

    await tester.pump(const Duration(seconds: 59));
    expect(find.text('4:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('discussion_reset')));
    await tester.pump();
    expect(find.text('5:00'), findsOneWidget);
  });

  testWidgets('a team can only be confirmed at the exact quest size', (
    tester,
  ) async {
    await startMatch(tester);
    await reachDay(tester);

    await tester.tap(find.byKey(const Key('dashboard_choose_team')));
    await tester.pumpAndSettle();
    expect(find.text('CHOOSE THE TEAM'), findsOneWidget);
    expect(find.text('2 / 2'), findsNothing);
    expect(enabled(tester, const Key('team_selection_confirm')), isFalse);

    await tester.tap(find.byKey(const Key('team_selection_seat_1')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(enabled(tester, const Key('team_selection_confirm')), isFalse);

    // One more seat completes the team; a third tap is ignored.
    await tester.tap(find.byKey(const Key('team_selection_seat_2')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(enabled(tester, const Key('team_selection_confirm')), isTrue);

    await tester.tap(find.byKey(const Key('team_selection_seat_3')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget,
        reason: 'the team cannot grow past the quest size');

    // Deselecting frees a slot again.
    await tester.tap(find.byKey(const Key('team_selection_seat_1')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(enabled(tester, const Key('team_selection_confirm')), isFalse);

    await tester.tap(find.byKey(const Key('team_selection_seat_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team_selection_confirm')));
    await tester.pumpAndSettle();

    expect(find.text('TEAM VOTING'), findsWidgets);
    expect(find.byKey(const Key('dashboard_open_vote')), findsOneWidget);
  });

  testWidgets('leaving team selection keeps the proposed team recoverable', (
    tester,
  ) async {
    await startMatch(tester);
    await reachDay(tester);

    await tester.tap(find.byKey(const Key('dashboard_choose_team')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team_selection_seat_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team_selection_back')));
    await tester.pumpAndSettle();

    expect(find.text('TEAM SELECTION'), findsWidgets);
    expect(find.text('Continue Team Selection'), findsOneWidget);
  });
}
