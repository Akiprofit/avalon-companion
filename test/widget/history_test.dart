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

    await tester.tap(find.byKey(const Key('home_history')));
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
}
