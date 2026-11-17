import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/database/database_provider.dart';
import 'package:avalon_companion/database/match_store.dart';
import 'package:avalon_companion/game_engine/models/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_match_store.dart';

/// Phase 9 gate: the history screen shows what was actually stored, and says so
/// plainly when nothing was.
void main() {
  Future<void> pumpHistory(WidgetTester tester, FakeMatchStore store) async {
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

    await tester.tap(find.byKey(const Key('nav_history')));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty history invites the first match', (tester) async {
    final store = FakeMatchStore();
    await pumpHistory(tester, store);

    expect(find.text('GAME HISTORY'), findsOneWidget);
    expect(find.text('No matches yet'), findsOneWidget);
  });

  testWidgets('stored matches are listed newest first with their outcome', (
    tester,
  ) async {
    final store = FakeMatchStore()
      ..summaries = [
        summaryOf(id: 2, winner: 'evil', winReason: WinReason.assassination),
        summaryOf(id: 1),
        summaryOf(
          id: 3,
          status: MatchStatus.abandoned,
          winner: null,
          winReason: null,
          questResults: const [QuestResult.success],
        ),
      ];

    await pumpHistory(tester, store);

    expect(find.text('PAST MATCHES'), findsOneWidget);
    expect(find.text('3 stored'), findsOneWidget);
    expect(find.text('Good victory'), findsOneWidget);
    expect(find.text('Evil victory'), findsOneWidget);
    expect(find.text('Abandoned'), findsOneWidget);
    expect(
      find.textContaining('Merlin survived the accusation'),
      findsOneWidget,
    );
    expect(find.textContaining('Left unfinished'), findsOneWidget);
    // The quest tally is not repeated when the win reason already says it.
    expect(find.text('Three quests won · 15:00'), findsOneWidget);
    expect(find.text('Left unfinished · 1 of 5 quests won'), findsOneWidget);
  });

  testWidgets('a running match is marked as still running', (tester) async {
    final store = FakeMatchStore()
      ..summaries = [
        summaryOf(
          id: 9,
          status: MatchStatus.inProgress,
          winner: null,
          winReason: null,
          questResults: const [QuestResult.success, QuestResult.fail],
          durationSeconds: null,
        ),
      ];

    await pumpHistory(tester, store);

    expect(find.text('In progress'), findsOneWidget);
    expect(find.textContaining('Still running'), findsOneWidget);
  });

  testWidgets('history never shows a player name', (tester) async {
    final store = FakeMatchStore()..summaries = [summaryOf()];
    await pumpHistory(tester, store);

    for (final name in ['Ann', 'Ben', 'Cara', 'Dev', 'Eli']) {
      expect(find.textContaining(name), findsNothing);
    }
  });

  testWidgets('a stored match opens its quest-by-quest record', (tester) async {
    final store = FakeMatchStore()
      ..summaries = [
        summaryOf(
          id: 7,
          questResults: const [QuestResult.success, QuestResult.fail],
          questTeams: const [
            [1, 2],
            [3, 4, 5],
          ],
          rejectionCount: 2,
        ),
      ];

    await pumpHistory(tester, store);
    await tester.tap(find.byKey(const Key('history_match_7')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history_detail_sheet')), findsOneWidget);
    expect(find.byKey(const Key('history_detail_title')), findsOneWidget);
    expect(find.text('Quest 1 · won'), findsOneWidget);
    expect(find.text('Seats 1, 2 went on the quest.'), findsOneWidget);
    expect(find.text('Quest 2 · lost'), findsOneWidget);
    expect(find.text('Seats 3, 4, 5 went on the quest.'), findsOneWidget);
    expect(find.text('The remaining quests were not played.'), findsOneWidget);
    expect(find.text('Proposals rejected in the last round'), findsOneWidget);
    expect(find.textContaining('Roles are never stored'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history_detail_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_detail_sheet')), findsNothing);
    expect(find.byKey(const Key('history_match_7')), findsOneWidget);
  });

  group('clearing history', () {
    testWidgets('deletes the chosen number, oldest first', (tester) async {
      final store = FakeMatchStore()
        ..summaries = [
          summaryOf(id: 3, startedAt: DateTime(2026, 11, 15, 21)),
          summaryOf(id: 2, startedAt: DateTime(2026, 11, 15, 20)),
          summaryOf(id: 1, startedAt: DateTime(2026, 11, 15, 19)),
        ];
      await pumpHistory(tester, store);

      await tester.tap(find.byKey(const Key('history_clear')));
      await tester.pumpAndSettle();

      expect(find.text('Clear history'), findsOneWidget);
      expect(find.text('Delete the oldest 1'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('history_clear_value'))).data,
        '1',
      );

      await tester.tap(find.byKey(const Key('history_clear_increment')));
      await tester.pumpAndSettle();
      expect(find.text('Delete the oldest 2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('history_clear_confirm')));
      await tester.pumpAndSettle();

      expect(store.summaries.map((summary) => summary.id), [
        3,
      ], reason: 'the two oldest matches went, the newest stayed');
      expect(find.text('Deleted 2 matches.'), findsOneWidget);
      expect(find.text('1 stored'), findsOneWidget);

      // Let the snack bar retire so no timer outlives the test.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('the All action deletes every stored match', (tester) async {
      final store = FakeMatchStore()
        ..summaries = [
          summaryOf(id: 2, startedAt: DateTime(2026, 11, 15, 20)),
          summaryOf(id: 1, startedAt: DateTime(2026, 11, 15, 19)),
        ];
      await pumpHistory(tester, store);

      await tester.tap(find.byKey(const Key('history_clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history_clear_all')));
      await tester.pumpAndSettle();

      expect(find.text('Delete all 2 matches'), findsOneWidget);
      await tester.tap(find.byKey(const Key('history_clear_confirm')));
      await tester.pumpAndSettle();

      expect(store.summaries, isEmpty);
      expect(find.text('Deleted 2 matches.'), findsOneWidget);
      expect(find.text('No matches yet'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('a match in progress is never deleted', (tester) async {
      final store = FakeMatchStore()
        ..summaries = [
          summaryOf(
            id: 2,
            status: MatchStatus.inProgress,
            winner: null,
            winReason: null,
            questResults: const [QuestResult.success],
            durationSeconds: null,
          ),
          summaryOf(id: 1, startedAt: DateTime(2026, 11, 15, 19)),
        ];
      await pumpHistory(tester, store);

      await tester.tap(find.byKey(const Key('history_clear')));
      await tester.pumpAndSettle();

      expect(find.text('The match in progress is kept.'), findsOneWidget);
      expect(
        find.text('All 1'),
        findsNothing,
        reason: 'one match is all of them',
      );
      expect(find.text('Delete the match'), findsOneWidget);

      await tester.tap(find.byKey(const Key('history_clear_confirm')));
      await tester.pumpAndSettle();

      expect(store.summaries.map((summary) => summary.id), [2]);
      expect(find.text('Deleted 1 match.'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('the clear action is inert when nothing can go', (
      tester,
    ) async {
      final store = FakeMatchStore()
        ..summaries = [
          summaryOf(
            id: 1,
            status: MatchStatus.inProgress,
            winner: null,
            winReason: null,
            questResults: const [],
            durationSeconds: null,
          ),
        ];
      await pumpHistory(tester, store);

      expect(find.text('1 stored'), findsOneWidget);
      await tester.tap(find.byKey(const Key('history_clear')));
      await tester.pumpAndSettle();

      expect(find.text('Clear history'), findsNothing);
      expect(store.summaries, hasLength(1));
    });

    testWidgets('backing out keeps the history', (tester) async {
      final store = FakeMatchStore()..summaries = [summaryOf()];
      await pumpHistory(tester, store);

      await tester.tap(find.byKey(const Key('history_clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history_clear_cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Clear history'), findsNothing);
      expect(store.summaries, hasLength(1));
      expect(find.textContaining('Deleted'), findsNothing);
    });
  });
}
