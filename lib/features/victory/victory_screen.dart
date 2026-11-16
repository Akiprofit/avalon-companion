import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/quest_log.dart';
import '../../core/widgets/quest_tracker.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../game_engine/controllers/game_session_controller.dart';
import '../../game_engine/models/game_state.dart';
import '../../game_engine/models/phase.dart';
import '../settings/settings_controller.dart';

/// Screen 12 â€” the end of the match.
///
/// Two distinct treatments, one per side: royal gold for Good, crimson and
/// gold for Evil. The summary is public information only â€” quests, rejections
/// and duration. No character is ever attached to a player.
class VictoryScreen extends ConsumerWidget {
  const VictoryScreen({super.key});

  /// The one sentence that explains how the match ended.
  String _reason(GameState game) {
    if (game.phase == Phase.goodVictory) {
      return 'Three quests were won and Merlin survived the accusation.';
    }
    if (game.merlinIdentified == true) {
      return 'The assassin named Merlin after three quests were won.';
    }
    if (game.questFailures >= 3) {
      return 'Three quests failed. The realm fell.';
    }
    return 'Five proposals were rejected in a row. The table deadlocked.';
  }

  String _duration(GameState game) {
    final end = game.finishedAt ?? DateTime.now();
    final span = end.difference(game.startedAt);
    if (span.inMinutes < 1) return 'under a minute';
    final hours = span.inHours;
    final minutes = span.inMinutes % 60;
    if (hours == 0) return '$minutes min';
    return '$hours h $minutes min';
  }

  /// Same table, fresh match: the roster and the composition carry over, every
  /// quest, vote, rejection, the drawn Lord and the result are cleared.
  Future<void> _playAgain(BuildContext context, WidgetRef ref) async {
    final game = ref.read(gameSessionProvider);
    if (game == null) return;
    final confirmed =
        !ref.read(settingsConfirmProvider) ||
        await confirmAction(
          context,
          ref,
          title: 'Play again?',
          message:
              'A new match begins with the same ${game.playerCount} players. '
              'Quest teams, votes, quest results, the drawn Lord and this '
              'result are cleared, and the cards are dealt again from the '
              'physical deck.',
          confirmLabel: 'Start new match',
          isDestructive: false,
        );
    if (!confirmed || !context.mounted) return;
    // The new match is already created in the preparation phase, so the table
    // goes straight to the round table. Bouncing through the setup screens
    // would leave the MC on a disabled "Begin the match" button, because that
    // screen starts a match from the setup draft, not from the live one.
    ref.read(gameSessionProvider.notifier).playAgain();
    context.goNamed(RouteNames.dashboard);
  }

  /// Leaving a finished match keeps its record, so the home screen can offer
  /// "Review the Last Match". New Match is what clears it.
  void _goHome(BuildContext context) {
    context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameSessionProvider);
    if (game == null || !game.phase.isVictory) {
      return AvalonScreen(
        appBar: AppBar(title: const Text('THE RESULT')),
        backgroundImage: Artwork.results,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No match has ended yet.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.lg),
              PrimaryButton(
                key: const Key('victory_none_home'),
                label: 'Return Home',
                icon: Icons.home_outlined,
                onPressed: () => context.goNamed(RouteNames.home),
              ),
            ],
          ),
        ),
      );
    }

    final good = game.phase == Phase.goodVictory;
    final accent = good ? AppColors.lightGold : AppColors.danger;

    return AvalonScreen(
      padded: false,
      backgroundImage: good ? Artwork.results : Artwork.excalibur,
      appBar: AppBar(
        title: Text(good ? 'GOOD VICTORY' : 'EVIL VICTORY'),
        leading: IconButton(
          key: const Key('victory_home_icon'),
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
          onPressed: () => _goHome(context),
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
            PrimaryButton(
              key: const Key('victory_play_again'),
              label: 'Play Again',
              icon: Icons.replay_rounded,
              onPressed: () => _playAgain(context, ref),
            ),
            const SizedBox(height: Space.xs),
            SecondaryButton(
              key: const Key('victory_home'),
              label: 'Main Menu',
              icon: Icons.home_outlined,
              onPressed: () => _goHome(context),
            ),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screenPadding,
          Space.xl,
          Space.screenPadding,
          Space.xl,
        ),
        children: [
          Icon(
            good ? Icons.shield_outlined : Icons.gavel_rounded,
            size: 56,
            color: accent,
          ),
          const SizedBox(height: Space.md),
          Text(
            good ? 'GOOD VICTORY' : 'EVIL VICTORY',
            key: const Key('victory_title'),
            style: AppText.display.copyWith(
              fontSize: 34,
              letterSpacing: 4,
              color: accent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.sm),
          Text(
            _reason(game),
            key: const Key('victory_reason'),
            style: AppText.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.lg),
          SectionHeader(
            title: 'The five quests',
            trailing: MetaPill(label: '${game.questResults.length} played'),
          ),
          MedievalCard(child: QuestTracker(slots: game.questSlots)),
          if (game.questLog.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            const SectionHeader(title: 'The board, quest by quest'),
            MedievalCard(child: QuestLog(game: game)),
          ],
          const SizedBox(height: Space.lg),
          const SectionHeader(title: 'Final summary'),
          MedievalCard(
            child: Column(
              children: [
                _SummaryRow(label: 'Players', value: '${game.playerCount}'),
                _SummaryRow(
                  label: 'Quests won by Good',
                  value: '${game.questSuccesses}',
                  tone: AppColors.success,
                ),
                _SummaryRow(
                  label: 'Quests lost to Evil',
                  value: '${game.questFailures}',
                  tone: AppColors.danger,
                ),
                _SummaryRow(
                  label: 'Proposals rejected in the last round',
                  value: '${game.rejectionCount}',
                ),
                _SummaryRow(
                  label: 'Match length',
                  value: _duration(game),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          MedievalCard(
            child: Text(
              good
                  ? 'Good held the realm. The record above lists the teams that '
                        'played and the quests they won or lost, never a role.'
                  : 'Evil took the realm. The record above lists the teams that '
                        'played and the quests they won or lost, never a role.',
              style: AppText.caption,
            ),
          ),
        ],
      ),
    );
  }
}

/// One label/value line in the final summary.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.tone,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Color? tone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.body.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: Space.sm),
              Text(
                value,
                style: AppText.bodyStrong.copyWith(color: tone),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
