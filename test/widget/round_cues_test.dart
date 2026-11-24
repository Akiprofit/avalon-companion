import 'package:avalon_companion/app/app.dart';
import 'package:avalon_companion/game_engine/controllers/game_session_controller.dart';
import 'package:avalon_companion/game_engine/models/character.dart';
import 'package:avalon_companion/game_engine/models/composition.dart';
import 'package:avalon_companion/game_engine/models/phase.dart';
import 'package:avalon_companion/game_engine/rules/avalon_tables.dart';
import 'package:avalon_companion/narration_engine/services/clip_provider.dart';
import 'package:avalon_companion/narration_engine/services/clip_service.dart';
import 'package:avalon_companion/narration_engine/services/narration_clips.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The round lines are announced by the screens themselves: the MC should not
/// have to remember to play them, so each one is spoken at the moment the table
/// reaches it.
void main() {
  late _RecordingClipService clips;

  setUp(() => clips = _RecordingClipService());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [clipServiceProvider.overrideWithValue(clips)],
        child: const AvalonApp(),
      ),
    );
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

  String clip(String id) =>
      '${NarrationClips.directory}/en/$id.mp3';

  testWidgets('a proposed team, an approved vote and a quest are announced', (
    tester,
  ) async {
    await reachDay(tester);

    await tester.tap(find.byKey(const Key('dashboard_choose_team')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team_selection_seat_1')));
    await tester.tap(find.byKey(const Key('team_selection_seat_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team_selection_confirm')));
    await tester.pumpAndSettle();

    expect(
      clips.played,
      contains(clip('round.proposal')),
      reason: 'the leader has just named a team',
    );

    await tester.tap(find.byKey(const Key('dashboard_open_vote')));
    await tester.pumpAndSettle();
    for (var seat = 1; seat <= 5; seat++) {
      await tester.tap(find.byKey(Key('vote_seat_${seat}_approve')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('voting_resolve')));
    await tester.pumpAndSettle();

    expect(
      clips.played,
      contains(clip('vote.approved')),
      reason: 'the table has just approved the team',
    );

    await tester.tap(find.byKey(const Key('voting_outcome_continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboard_resolve_quest')));
    await tester.pumpAndSettle();
    // A two-seat quest: both cards are counted before it can be recorded.
    await tester.tap(find.byKey(const Key('quest_success_increment')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quest_success_increment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quest_resolve')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quest_confirm_save')));
    await tester.pumpAndSettle();

    expect(
      clips.played,
      contains(clip('quest.success')),
      reason: 'the quest was just recorded as a success',
    );
  });

  testWidgets('the accusation announces itself when the screen opens', (
    tester,
  ) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AvalonApp)),
    );
    final defaults = AvalonTables.defaultComposition(5);
    container.read(gameSessionProvider.notifier).start(
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

    // Three successful quests, driven through the engine: the screen is what
    // announces the accusation, not the store.
    for (final teamSize in [2, 3, 2]) {
      final controller = container.read(gameSessionProvider.notifier);
      if (container.read(gameSessionProvider)?.phase == Phase.preparation) {
        controller.startNight();
      }
      if (container.read(gameSessionProvider)?.phase == Phase.night) {
        controller.endNight();
      }
      if (container.read(gameSessionProvider)?.phase == Phase.lordSelection) {
        controller.chooseLord(1);
      }
      if (container.read(gameSessionProvider)?.phase == Phase.dayDiscussion) {
        controller.beginTeamSelection();
      }
      controller.proposeTeam([for (var seat = 1; seat <= teamSize; seat++) seat]);
      controller.recordVotes(approve: 5, reject: 0);
      controller.resolveTeamVote();
      controller.recordQuest(failCards: 0);
    }
    expect(container.read(gameSessionProvider)?.phase, Phase.assassination);

    await tester.pump();
    await tester.tap(find.byKey(const Key('home_continue_game')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboard_open_assassination')));
    // The clock ticks every second, so settling would run the whole two minutes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      clips.played,
      contains(clip('assassination.begin')),
      reason: 'the assassin has just woken',
    );
  });
}

class _RecordingClipService implements ClipService {
  final played = <String>[];

  @override
  bool get isAvailable => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> play(String assetPath, {required double volume}) async {
    played.add(assetPath);
    return true;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
