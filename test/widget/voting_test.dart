import 'package:avalon_companion/app/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 6 gate: physical votes are recorded accurately and the engine decides
/// the outcome from them, never from the UI.
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

  /// Five-player match, night skipped, at the dashboard in Day.
  Future<void> reachDay(WidgetTester tester) async {
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
  }

  /// Day -> team selection -> proposed team -> open vote.
  Future<void> openVote(WidgetTester tester) async {
    await reachDay(tester);
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
  }

  bool enabled(WidgetTester tester, Key key) {
    final semantics = tester.widget<Semantics>(
      find
          .descendant(of: find.byKey(key), matching: find.byType(Semantics))
          .first,
    );
    return semantics.properties.enabled ?? false;
  }

  /// Marks seats in the voting list. Keying by seat keeps the test close to
  /// what the MC sees at the table.
  Future<void> mark(WidgetTester tester, Map<int, bool> votes) async {
    for (final entry in votes.entries) {
      final side = entry.value ? 'approve' : 'reject';
      await tester.tap(find.byKey(Key('vote_seat_${entry.key}_$side')));
      await tester.pump();
    }
  }

  testWidgets('the vote only resolves when every player is counted', (
    tester,
  ) async {
    await openVote(tester);

    expect(find.text('THE VOTE'), findsWidgets);
    expect(find.byKey(const Key('voting_resolve')), findsOneWidget);
    expect(enabled(tester, const Key('voting_resolve')), isFalse);
    expect(find.text('Waiting for 5 votes.'), findsOneWidget);

    await mark(tester, {1: true, 2: true, 3: false});
    expect(find.text('Waiting for 2 votes.'), findsOneWidget);
    expect(enabled(tester, const Key('voting_resolve')), isFalse);

    await mark(tester, {4: false, 5: false});
    expect(enabled(tester, const Key('voting_resolve')), isTrue);
    expect(find.text('This vote rejects the team.'), findsOneWidget);
  });

  testWidgets('a vote can be cleared and recast on the same seat', (
    tester,
  ) async {
    await openVote(tester);

    await mark(tester, {1: true});
    expect(find.text('Waiting for 4 votes.'), findsOneWidget);

    // Tapping the same side again clears the seat instead of double-counting.
    await mark(tester, {1: true});
    expect(find.text('Waiting for 5 votes.'), findsOneWidget);

    // The row itself cycles approve -> reject -> uncounted.
    await tester.tap(find.byKey(const Key('vote_seat_2')));
    await tester.pump();
    expect(find.text('Approve 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('vote_seat_2')));
    await tester.pump();
    expect(find.text('Reject 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('vote_seat_2')));
    await tester.pump();
    expect(find.text('Waiting for 5 votes.'), findsOneWidget);
  });

  testWidgets('a miscount can be corrected before resolving', (tester) async {
    await openVote(tester);

    // Five rejections, then one corrected to an approval.
    await mark(tester, {1: false, 2: false, 3: false, 4: false, 5: false});
    expect(find.text('This vote rejects the team.'), findsOneWidget);

    await mark(tester, {1: true});
    expect(find.text('Approve 1'), findsOneWidget);
    expect(find.text('Reject 4'), findsOneWidget);
    expect(find.text('This vote rejects the team.'), findsOneWidget);

    // Two approvals against three rejections still loses; the total stays five.
    await mark(tester, {2: true});
    expect(find.text('Approve 2'), findsOneWidget);
    expect(find.text('Reject 3'), findsOneWidget);
    expect(find.text('This vote rejects the team.'), findsOneWidget);
    expect(enabled(tester, const Key('voting_resolve')), isTrue);
  });

  testWidgets('an approved vote sends the match to quest resolution', (
    tester,
  ) async {
    await openVote(tester);
    await mark(tester, {1: true, 2: true, 3: true, 4: true, 5: false});
    expect(find.text('This vote approves the team.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('voting_resolve')));
    await tester.pumpAndSettle();

    expect(find.text('The team is approved'), findsOneWidget);
    await tester.tap(find.byKey(const Key('voting_outcome_continue')));
    await tester.pumpAndSettle();

    expect(find.text('QUEST RESOLUTION'), findsWidgets);
    expect(find.byKey(const Key('dashboard_open_vote')), findsNothing);
  });

  testWidgets('a rejected vote returns the table to Day', (tester) async {
    await openVote(tester);

    // Player 1 leads the first quest; the token must move on rejection.
    expect(find.text('Player 1'), findsWidgets);
    await mark(tester, {1: true, 2: true, 3: false, 4: false, 5: false});

    await tester.tap(find.byKey(const Key('voting_resolve')));
    await tester.pumpAndSettle();
    expect(find.text('The team is rejected'), findsOneWidget);
    await tester.tap(find.byKey(const Key('voting_outcome_continue')));
    await tester.pumpAndSettle();

    expect(find.text('DAY'), findsWidgets);
    expect(find.byKey(const Key('dashboard_choose_team')), findsOneWidget);
  });
}
