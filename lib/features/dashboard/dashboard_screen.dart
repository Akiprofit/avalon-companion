import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_icon_button.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/game_progress_header.dart';
import '../../core/widgets/mc_pin_dialog.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/player_grid.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/quest_board.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_indicator.dart';
import '../../game_engine/controllers/game_session_controller.dart';
import '../../game_engine/models/phase.dart';
import '../../game_engine/rules/avalon_tables.dart';
import '../settings/settings_controller.dart';
import 'discussion_timer_controller.dart';

/// Screen 10 — the MC's home base during a match.
///
/// Only controls that exist in this build are shown; later phases add team
/// selection, voting and quest resolution here as their features land.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameSessionProvider);
    if (game == null) {
      return AvalonScreen(
        appBar: AppBar(title: const Text('THE ROUND TABLE')),
        child: EmptyState(
          key: const Key('dashboard_no_match'),
          title: 'No match in progress',
          message:
              'Start a new match or continue the last one from the home '
              'screen.',
          icon: Icons.castle_outlined,
          action: PrimaryButton(
            label: 'Back to Home',
            icon: Icons.home_outlined,
            onPressed: () => context.goNamed(RouteNames.home),
          ),
        ),
      );
    }
    final timer = ref.watch(discussionTimerProvider);
    // The last ten seconds are the ones the table needs to see from a distance.
    final timerUrgent = timer.remainingSeconds <= 10;

    final requiredSize = AvalonTables.teamSize(
      game.playerCount,
      game.questNumber,
    );
    final isPaused = game.phase == Phase.paused;
    final finished = game.phase.isVictory;
    final narrationAvailable = !isPaused;
    final isDiscussion =
        game.phase == Phase.dayDiscussion || game.phase == Phase.teamSelection;
    final canOpenNarration =
        game.phase == Phase.preparation || game.phase == Phase.night;
    // In the manual King mode the MC asks for a draw between rounds; the wheel
    // stays closed otherwise.
    final kingsManual = ref.watch(
      settingsProvider.select((s) => !s.kingsDrawnAutomatically),
    );
    final voteOn = ref.watch(settingsProvider.select((s) => s.teamVoteEnabled));
    final canDrawKing =
        kingsManual &&
        (game.phase == Phase.dayDiscussion ||
            game.phase == Phase.teamSelection);

    return AvalonScreen(
      padded: false,
      backgroundImage: Artwork.dashboard,
      appBar: AppBar(
        title: const Text('THE ROUND TABLE'),
        leading: IconButton(
          key: const Key('dashboard_home'),
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
          onPressed: () async {
            final leave =
                !ref.read(settingsConfirmProvider) ||
                await confirmAction(
                  context,
                  ref,
                  title: 'Leave the match?',
                  message:
                      'The match stays in progress. You can continue it from '
                      'the home screen.',
                  confirmLabel: 'Leave match',
                  isDestructive: false,
                );
            if (leave && context.mounted) context.goNamed(RouteNames.home);
          },
        ),
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.screenPadding,
          Space.xs,
          Space.screenPadding,
          Space.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (game.phase == Phase.lordSelection)
              PrimaryButton(
                key: const Key('dashboard_choose_lord'),
                label: 'Choose the Lord',
                icon: Icons.casino_outlined,
                onPressed: () => context.goNamed(RouteNames.lordSelection),
              )
            else if (isDiscussion)
              PrimaryButton(
                key: const Key('dashboard_choose_team'),
                label: game.phase == Phase.teamSelection
                    ? 'Continue Team Selection'
                    : 'Choose the Quest Team',
                icon: Icons.groups_rounded,
                onPressed: () => context.goNamed(RouteNames.teamSelection),
              )
            else if (game.phase == Phase.teamVoting)
              PrimaryButton(
                key: const Key('dashboard_open_vote'),
                label: 'Open the Vote',
                icon: Icons.how_to_vote_outlined,
                onPressed: () => context.goNamed(RouteNames.voting),
              )
            else if (game.phase == Phase.questResolution)
              PrimaryButton(
                key: const Key('dashboard_resolve_quest'),
                label: 'Resolve the Quest',
                icon: Icons.shield_outlined,
                onPressed: () => context.goNamed(RouteNames.questResolution),
              )
            else if (game.phase == Phase.assassination)
              PrimaryButton(
                key: const Key('dashboard_open_assassination'),
                label: 'Begin the Accusation',
                icon: Icons.gavel_rounded,
                onPressed: () => context.goNamed(RouteNames.assassination),
              )
            else if (game.phase.isVictory)
              PrimaryButton(
                key: const Key('dashboard_open_results'),
                label: 'See the Result',
                icon: Icons.emoji_events_outlined,
                onPressed: () => context.goNamed(RouteNames.results),
              )
            else
              PrimaryButton(
                key: const Key('dashboard_open_narration'),
                label: 'Open Night Narration',
                icon: Icons.nightlight_round,
                onPressed: canOpenNarration && narrationAvailable
                    ? () => context.goNamed(RouteNames.narration)
                    : null,
              ),
            if (canDrawKing) ...[
              const SizedBox(height: Space.xs),
              SecondaryButton(
                key: const Key('dashboard_draw_king'),
                label: 'Draw a new King',
                icon: Icons.casino_outlined,
                onPressed: () {
                  ref.read(gameSessionProvider.notifier).beginLordDraw();
                  context.goNamed(RouteNames.lordSelection);
                },
              ),
            ],
            if (!finished) ...[
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  Expanded(
                    child: _SmallAction(
                      key: const Key('dashboard_pause'),
                      icon: isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      label: isPaused ? 'Resume' : 'Pause',
                      onPressed: () =>
                          ref.read(gameSessionProvider.notifier).togglePause(),
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: _SmallAction(
                      key: const Key('dashboard_abort'),
                      icon: Icons.stop_circle_outlined,
                      label: 'Abort',
                      tone: AppColors.danger,
                      onPressed: () async {
                        final allowed = await requestPin(
                          context,
                          ref,
                          title: 'Abort the match',
                          message:
                              'Aborting discards the round in progress. '
                              'Enter the MC PIN to continue.',
                          confirmLabel: 'Proceed',
                        );
                        if (!allowed || !context.mounted) return;
                        final confirmed = await confirmAction(
                          context,
                          ref,
                          title: 'Abort the match?',
                          message:
                              'The current round, the quest results and the '
                              'leader rotation will be lost.',
                          confirmLabel: 'Abort match',
                        );
                        if (!confirmed || !context.mounted) return;
                        ref.read(gameSessionProvider.notifier).abort();
                        context.goNamed(RouteNames.home);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      child: Column(
        children: [
          GameProgressHeader(
            leaderName: game.phase == Phase.lordSelection
                ? 'To be chosen'
                : game.leader.displayName,
            questNumber: game.questNumber,
            requiredTeamSize: requiredSize,
            rejectionCount: game.rejectionCount,
            showRejections: voteOn,
            phaseLabel: game.phase.label,
            phaseTone: isPaused ? StatusTone.danger : StatusTone.active,
            questSlots: game.questSlots,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.screenPadding,
                Space.md,
                Space.screenPadding,
                Space.xl,
              ),
              children: [
                // One line of what to do next, right under the score, so an MC
                // running their first match never has to guess the next step.
                MedievalCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.mutedGold,
                      ),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(
                          isPaused
                              ? 'The match is paused. Resume when the table is '
                                    'ready.'
                              : finished
                              ? 'The match is over. Open the result to review '
                                    'the final summary.'
                              : switch (game.phase) {
                                  Phase.preparation =>
                                    'Read the introduction aloud, then start '
                                        'the night narration.',
                                  Phase.night =>
                                    'Wake the roles in order. The screen shows '
                                        'the script for each wake-up.',
                                  Phase.lordSelection =>
                                    'Draw the King for this round. The wheel '
                                        'picks the seat at random.',
                                  Phase.dayDiscussion =>
                                    'Let the table talk, then tap Choose the '
                                        'Quest Team.',
                                  Phase.teamSelection =>
                                    'Tap the players for this quest, then send '
                                        'them to the vote.',
                                  Phase.teamVoting =>
                                    'Count the hands, then record the vote on '
                                        'the next screen.',
                                  Phase.questResolution =>
                                    'Count the cards that came back from the '
                                        'quest, then record the result.',
                                  Phase.assassination =>
                                    'The assassin names a player. Record only '
                                        'whether it was Merlin.',
                                  _ =>
                                    'The match is waiting for the next step '
                                        'at the table.',
                                },
                          key: const Key('dashboard_next_hint'),
                          style: AppText.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
                const SectionHeader(title: 'The quests'),
                MedievalCard(child: QuestBoard(game: game)),
                if (isDiscussion) ...[
                  const SizedBox(height: Space.lg),
                  SectionHeader(
                    title: 'Discussion',
                    trailing: MetaPill(
                      label: timer.isFinished
                          ? "Time's up"
                          : timer.isRunning
                          ? 'Running'
                          : 'Paused',
                    ),
                  ),
                  MedievalCard(
                    child: Row(
                      children: [
                        Semantics(
                          button: true,
                          label: timer.isFinished
                              ? 'The discussion is over. Tap to restart.'
                              : timer.isRunning
                              ? 'Pause the discussion timer'
                              : 'Start the discussion timer',
                          child: InkResponse(
                            key: const Key('discussion_ring'),
                            onTap: timer.isFinished
                                ? () => ref
                                      .read(discussionTimerProvider.notifier)
                                      .reset()
                                : () => ref
                                      .read(discussionTimerProvider.notifier)
                                      .toggle(),
                            containedInkWell: true,
                            highlightShape: BoxShape.circle,
                            radius: 40,
                            child: SizedBox(
                              width: 76,
                              height: 76,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 76,
                                    height: 76,
                                    child: CircularProgressIndicator(
                                      value: timer.totalSeconds == 0
                                          ? 0
                                          : timer.remainingSeconds /
                                                timer.totalSeconds,
                                      strokeWidth: 6,
                                      backgroundColor: AppColors.surfaceRaised,
                                      color: timerUrgent
                                          ? AppColors.danger
                                          : AppColors.gold,
                                    ),
                                  ),
                                  Text(
                                    timer.label,
                                    key: const Key('discussion_time'),
                                    style: AppText.numeral.copyWith(
                                      fontSize: 20,
                                      color: timerUrgent
                                          ? AppColors.danger
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                timer.isFinished
                                    ? "Time's up"
                                    : timer.isRunning
                                    ? 'Discussion running'
                                    : 'Discussion paused',
                                style: AppText.bodyStrong,
                              ),
                              const SizedBox(height: Space.xxs),
                              Text(
                                timer.isFinished
                                    ? 'Tap the ring to start the next round.'
                                    : timer.isRunning
                                    ? 'Tap the ring to pause.'
                                    : 'Tap the ring to start.',
                                style: AppText.caption,
                              ),
                            ],
                          ),
                        ),
                        AvalonIconButton(
                          key: const Key('discussion_toggle'),
                          icon: timer.isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          semanticLabel: timer.isRunning
                              ? 'Pause the discussion timer'
                              : 'Start the discussion timer',
                          onPressed: timer.isFinished
                              ? () => ref
                                    .read(discussionTimerProvider.notifier)
                                    .reset()
                              : () => ref
                                    .read(discussionTimerProvider.notifier)
                                    .toggle(),
                        ),
                        const SizedBox(width: Space.xs),
                        AvalonIconButton(
                          key: const Key('discussion_reset'),
                          icon: Icons.restart_alt_rounded,
                          semanticLabel: 'Reset the discussion timer',
                          onPressed: () => ref
                              .read(discussionTimerProvider.notifier)
                              .reset(),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Space.lg),
                SectionHeader(
                  title: 'The round table',
                  trailing: MetaPill(label: '${game.playerCount} seated'),
                ),
                MedievalCard(
                  padding: const EdgeInsets.all(Space.xs),
                  child: PlayerGrid(
                    players: game.players,
                    leaderSeat: game.leaderSeat,
                    selectedSeats: game.currentTeam.toSet(),
                  ),
                ),
                const SizedBox(height: Space.lg),
                const SectionHeader(title: 'In play'),
                MedievalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(game.compositionSummary, style: AppText.body),
                      const SizedBox(height: Space.xs),
                      Text(
                        'Characters in play for this match. The app does not '
                        'know who holds which card.',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tone = AppColors.parchment,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kMinTapTarget,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.input),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: tone),
              const SizedBox(width: Space.xxs),
              Text(
                label,
                style: AppText.button.copyWith(color: tone, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
