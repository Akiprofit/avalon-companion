import 'package:avalon_companion/app/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 7 gate: the MC counts the physical quest cards, the screen only
/// checks the total, and the engine decides the quest outcome and the score.
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

  bool enabled(WidgetTester tester, Key key) {
    final semantics = tester.widget<Semantics>(
      find
          .descendant(of: find.byKey(key), matching: find.byType(Semantics))
          .first,
    );
    return semantics.properties.enabled ?? false;
  }

  Future<void> addCards(
    WidgetTester tester, {
    required int success,
    required int fail,
  }) async {
    for (var i = 0; i < success; i++) {
      await tester.tap(find.byKey(const Key('quest_success_increment')));
      await tester.pump();
    }
    for (var i = 0; i < fail; i++) {
      await tester.tap(find.byKey(const Key('quest_fail_increment')));
      await tester.pump();
    }
  }

  /// Five-player match, night skipped, team of two approved, quest screen open.
  Future<void> openQuest(WidgetTester tester) async {
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
    await tester.tap(find.byKey(const Key('narration_end')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End the night'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lord_spin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lord_continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard_choose_team')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team_selection_seat_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team_selection_seat_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team_selection_confirm')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard_open_vote')));
    await tester.pumpAndSettle();
    for (var seat = 1; seat <= 4; seat++) {
      await tester.tap(find.byKey(Key('vote_seat_${seat}_approve')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('vote_seat_5_reject')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('voting_resolve')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voting_outcome_continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_resolve_quest')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dashboard_resolve_quest')));
    await tester.pumpAndSettle();
  }

  testWidgets('the quest only resolves when every card is counted', (
    tester,
  ) async {
    await openQuest(tester);

    expect(find.text('QUEST RESOLUTION'), findsWidgets);
    expect(enabled(tester, const Key('quest_resolve')), isFalse);
    expect(find.text('Waiting for 2 cards.'), findsOneWidget);
    expect(find.text('One fail card fails the quest.'), findsOneWidget);

    await addCards(tester, success: 1, fail: 0);
    expect(find.text('Waiting for 1 card.'), findsOneWidget);
    expect(enabled(tester, const Key('quest_resolve')), isFalse);
  });

  testWidgets('a miscount can be corrected before the quest is saved', (
    tester,
  ) async {
    await openQuest(tester);

    await addCards(tester, success: 2, fail: 0);
    expect(find.text('This quest succeeds.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quest_success_decrement')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quest_fail_increment')));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('quest_success_value'))).data,
      '1',
    );
    expect(find.text('This quest fails.'), findsOneWidget);
    expect(enabled(tester, const Key('quest_resolve')), isTrue);
  });

  testWidgets('the MC confirms the result before it is recorded', (
    tester,
  ) async {
    await openQuest(tester);
    await addCards(tester, success: 2, fail: 0);

    await tester.tap(find.byKey(const Key('quest_resolve')));
    await tester.pumpAndSettle();
    expect(find.text('Record a success?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quest_confirm_cancel')));
    await tester.pumpAndSettle();

    expect(find.text('This quest succeeds.'), findsOneWidget);
    expect(find.byKey(const Key('quest_outcome_continue')), findsNothing);
  });

  testWidgets('a successful quest returns to Day with the score at 1–0', (
    tester,
  ) async {
    await openQuest(tester);
    await addCards(tester, success: 2, fail: 0);

    await tester.tap(find.byKey(const Key('quest_resolve')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quest_confirm_save')));
    await tester.pumpAndSettle();

    expect(find.text('The quest succeeds'), findsOneWidget);
    expect(find.textContaining('Good 1 — Evil 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quest_outcome_continue')));
    await tester.pumpAndSettle();

    expect(find.text('DAY'), findsWidgets);
    expect(find.byKey(const Key('dashboard_choose_team')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_resolve_quest')), findsNothing);
  });

  testWidgets('a failed quest returns to Day with the score at 0–1', (
    tester,
  ) async {
    await openQuest(tester);
    await addCards(tester, success: 1, fail: 1);

    await tester.tap(find.byKey(const Key('quest_resolve')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quest_confirm_save')));
    await tester.pumpAndSettle();

    expect(find.text('The quest fails'), findsOneWidget);
    expect(find.textContaining('Good 0 — Evil 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quest_outcome_continue')));
    await tester.pumpAndSettle();

    expect(find.text('DAY'), findsWidgets);
    expect(find.byKey(const Key('dashboard_choose_team')), findsOneWidget);
  });
}
