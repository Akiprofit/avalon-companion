import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/core/widgets/primary_button.dart';
import 'package:avalon_companion/game_engine/controllers/game_session_controller.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Home is the door back into a live match, and the table reads as a grid.
void main() {
  Future<ProviderContainer> startMatch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: AvalonApp()));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AvalonApp)),
    );
    final defaults = AvalonTables.defaultComposition(5);
    container
        .read(gameSessionProvider.notifier)
        .start(
          names: const ['Ann', 'Ben', 'Cara', 'Dev', 'Eli'],
          composition: Composition(
            playerCount: 5,
            counts: {
              for (final character in Character.values)
                if ((defaults[character.label] ?? 0) > 0)
                  character: defaults[character.label]!,
            },
          ),
        );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('a live match is the hero, and New Game steps down', (
    tester,
  ) async {
    await startMatch(tester);

    expect(find.text('MATCH IN PROGRESS'), findsOneWidget);
    expect(find.text('5 players · Quest 1 of 5'), findsOneWidget);
    expect(find.text('No quests resolved yet.'), findsOneWidget);

    expect(
      tester.widget(find.byKey(const Key('home_continue_game'))),
      isA<PrimaryButton>(),
      reason: 'Continue Game is the gold action while a match is live',
    );
    expect(
      tester.widget(find.byKey(const Key('home_new_game'))),
      isNot(isA<PrimaryButton>()),
      reason: 'New Game is demoted to the secondary action',
    );

    expect(find.byKey(const Key('home_history')), findsNothing);
    expect(find.byKey(const Key('home_settings')), findsNothing);
    expect(find.byKey(const Key('home_how_to_play')), findsOneWidget);
  });

  testWidgets('the loose table is a two-column grid inside one card', (
    tester,
  ) async {
    await startMatch(tester);
    await tester.tap(find.byKey(const Key('home_continue_game')));
    await tester.pumpAndSettle();

    for (var seat = 1; seat <= 5; seat++) {
      final tile = find.byKey(Key('round_table_seat_$seat'));
      expect(tile, findsOneWidget);
      expect(tester.getSize(tile).height, lessThanOrEqualTo(64));
    }

    final first = tester.getRect(find.byKey(const Key('round_table_seat_1')));
    final second = tester.getRect(find.byKey(const Key('round_table_seat_2')));
    final third = tester.getRect(find.byKey(const Key('round_table_seat_3')));

    expect(second.top, first.top, reason: 'seats 1 and 2 share a row');
    expect(second.left, greaterThan(first.left));
    expect(third.left, first.left, reason: 'seat 3 wraps under seat 1');

    expect(
      find.descendant(
        of: find.byKey(const Key('round_table_seat_1')),
        matching: find.byIcon(Icons.workspace_premium_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('round_table_seat_2')),
        matching: find.byIcon(Icons.workspace_premium_outlined),
      ),
      findsNothing,
    );
  });
}
