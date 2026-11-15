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
import '../../core/widgets/game_progress_header.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/player_tile.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/quest_tracker.dart';
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
      return const AvalonScreen(child: SizedBox.shrink());
    }
    final timer = ref.watch(discussionTimerProvider);

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
            final leave = !ref.read(settingsConfirmProvider) ||
                await showConfirmation(
                  context,
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.sm),
            child: Center(
              child: StatusIndicator(
                label: isPaused ? 'PAUSED' : game.phase.label,
                tone: isPaused ? StatusTone.danger : StatusTone.active,
              ),
            ),
          ),
        ],
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
                      onPressed: () => ref
                          .read(gameSessionProvider.notifier)
                        .togglePause(),
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
                        final confirmed = await showConfirmation(
                          context,
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
            phaseLabel: game.phase.label,
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
                const SectionHeader(title: 'Quest progress'),
                MedievalCard(
                  child: QuestTracker(slots: game.questSlots),
                ),
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
                        Text(
                          timer.label,
                          key: const Key('discussion_time'),
                          style: AppText.numeral.copyWith(fontSize: 32),
                        ),
                        const Spacer(),
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
                  child: Column(
                    children: [
                      for (final player in game.players) ...[
                        if (player.seat > 1) const SizedBox(height: Space.xxs),
                        PlayerTile(
                          name: player.name,
                          seat: player.seat,
                          isLeader: player.seat == game.leaderSeat,
                          isSelected: game.currentTeam.contains(player.seat),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
                const SectionHeader(title: 'In play'),
                MedievalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.compositionSummary,
                        style: AppText.body,
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        'Characters in play for this match. The app does not '
                        'know who holds which card.',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
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
                              ? 'The match is paused. Resume to continue.'
                              : finished
                              ? 'The match is over. Open the result to review '
                                    'the final summary.'
                              : game.phase == Phase.lordSelection
                              ? 'Draw the first Lord of the match; the wheel '
                                    'picks the seat at random.'
                              : isDiscussion
                              ? 'Talk it through, then choose the quest team.'
                              : game.phase == Phase.teamVoting
                              ? 'Count the physical vote, then record it here.'
                              : game.phase == Phase.questResolution
                              ? 'Count the cards that came back from the quest.'
                              : game.phase == Phase.assassination
                              ? 'The table settles the accusation by hand, '
                                    'then the outcome is recorded.'
                              : canOpenNarration
                              ? 'Run the night narration for this composition.'
                              : 'The match is waiting for the next step at the '
                                    'table.',
                          style: AppText.caption,
                        ),
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
      height: 44,
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
              Text(label, style: AppText.button.copyWith(color: tone, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
