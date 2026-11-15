import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/counter_stepper.dart';
import '../../core/widgets/game_progress_header.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../game_engine/controllers/game_session_controller.dart';
import '../../game_engine/models/game_state.dart';
import '../../game_engine/models/phase.dart';

/// Screen 09 — the MC records the two cards played on the quest.
///
/// The table plays success and fail cards face down; the phone only counts
/// them. Success and fail totals must add up to the approved team, and the
/// engine — not the screen — decides whether the quest passes, including the
/// quest 4 two-fail rule.
class QuestResolutionScreen extends ConsumerStatefulWidget {
  const QuestResolutionScreen({super.key});

  @override
  ConsumerState<QuestResolutionScreen> createState() =>
      _QuestResolutionScreenState();
}

class _QuestResolutionScreenState extends ConsumerState<QuestResolutionScreen> {
  int _success = 0;
  int _fail = 0;
  bool _resolving = false;

  /// The quest as it stood when it resolved, so the frozen screen stays intact
  /// behind the outcome dialog while the phase has already moved on.
  GameState? _frozen;

  void _add({required bool success}) {
    final game = ref.read(gameSessionProvider);
    if (game == null) return;
    if (_success + _fail >= game.currentTeam.length) return;
    setState(() {
      if (success) {
        _success++;
      } else {
        _fail++;
      }
    });
  }

  void _remove({required bool success}) {
    setState(() {
      if (success) {
        if (_success > 0) _success--;
      } else {
        if (_fail > 0) _fail--;
      }
    });
  }

  Future<void> _resolve(GameState game) async {
    if (_resolving) return;
    final failed = _fail >= game.failsRequired;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(failed ? 'Record a failed quest?' : 'Record a success?'),
        content: Text(
          'Quest ${game.questNumber}: $_success success and $_fail '
          '${_fail == 1 ? 'fail card' : 'fail cards'}. '
          '${failed ? 'The quest fails' : 'The quest succeeds'}. '
          'This result cannot be edited afterwards.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            key: const Key('quest_confirm_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep counting'),
          ),
          TextButton(
            key: const Key('quest_confirm_save'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Record result'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _resolving = true;
      _frozen = game;
    });

    final controller = ref.read(gameSessionProvider.notifier);
    controller.recordQuest(failCards: _fail);
    final after = ref.read(gameSessionProvider);
    if (!mounted) return;

    final title = after?.phase == Phase.evilVictory
        ? 'Evil wins the match'
        : failed
        ? 'The quest fails'
        : 'The quest succeeds';
    final score =
        'Good ${after?.questSuccesses ?? 0} — '
        'Evil ${after?.questFailures ?? 0}';
    final message = after?.phase == Phase.evilVictory
        ? 'Three quests have failed. $score.'
        : after?.phase == Phase.assassination
        ? 'Three quests have succeeded. $score. The assassin now wakes and '
              'chooses a name.'
        : 'The leader token returns to the table. $score.';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message, style: AppText.body),
        actions: [
          TextButton(
            key: const Key('quest_outcome_continue'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Back to the table'),
          ),
        ],
      ),
    );
    if (mounted) context.goNamed(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(gameSessionProvider);
    final game = _frozen ??
        (live?.phase == Phase.questResolution ? live : null);
    final locked = _frozen != null;

    if (game == null) {
      return AvalonScreen(
        appBar: AppBar(title: const Text('QUEST RESOLUTION')),
        backgroundImage: Artwork.missionResults,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No quest is waiting to be resolved.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.xs),
              Text(
                'A quest is resolved after the table approves a team.',
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.lg),
              PrimaryButton(
                key: const Key('quest_none_back'),
                label: 'Back to the table',
                icon: Icons.arrow_back,
                onPressed: () => context.goNamed(RouteNames.dashboard),
              ),
            ],
          ),
        ),
      );
    }

    final team = [
      for (final player in game.players)
        if (game.currentTeam.contains(player.seat)) player,
    ];
    final teamSize = game.currentTeam.length;
    final remaining = teamSize - _success - _fail;
    final complete = remaining == 0;
    final failed = _fail >= game.failsRequired;

    return AvalonScreen(
      padded: false,
      backgroundImage: Artwork.missionResults,
      appBar: AppBar(
        title: const Text('QUEST RESOLUTION'),
        leading: IconButton(
          key: const Key('quest_back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(RouteNames.dashboard),
        ),
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.screenPadding,
          Space.xs,
          Space.screenPadding,
          Space.md,
        ),
        child: PrimaryButton(
          key: const Key('quest_resolve'),
          label: complete
              ? 'Resolve the quest'
              : 'Count ${remaining == 1 ? '1 more card' : '$remaining more cards'}',
          icon: complete ? Icons.gavel_rounded : Icons.style_outlined,
          onPressed: complete && !_resolving && !locked
              ? () => _resolve(game)
              : null,
        ),
      ),
      child: Column(
        children: [
          GameProgressHeader(
            leaderName: game.leader.displayName,
            questNumber: game.questNumber,
            requiredTeamSize: game.requiredTeamSize,
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
                const SectionHeader(title: 'The quest team'),
                MedievalCard(
                  child: team.isEmpty
                      ? Text('No team was approved.', style: AppText.body)
                      : Column(
                          children: [
                            for (var i = 0; i < team.length; i++) ...[
                              if (i > 0) const Divider(height: Space.md),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: Space.xs),
                                  Expanded(
                                    child: Text(
                                      team[i].name,
                                      style: AppText.bodyStrong,
                                    ),
                                  ),
                                  Text(
                                    'Seat ${team[i].seat}',
                                    style: AppText.caption,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: Space.lg),
                SectionHeader(
                  title: 'The cards played',
                  trailing: MetaPill(label: '$_success / $teamSize'),
                ),
                Text(
                  'Count the cards face down. Success and fail cards must add '
                  'up to $teamSize.',
                  style: AppText.caption,
                ),
                const SizedBox(height: Space.sm),
                Row(
                  children: [
                    Expanded(
                      child: CounterStepper(
                        key: const Key('quest_success'),
                        keyPrefix: 'quest_success',
                        label: 'SUCCESS',
                        icon: Icons.shield_outlined,
                        tone: AppColors.success,
                        value: _success,
                        max: teamSize,
                        onIncrement:
                            complete || locked ? null : () => _add(success: true),
                        onDecrement: _success == 0 || locked
                            ? null
                            : () => _remove(success: true),
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: CounterStepper(
                        key: const Key('quest_fail'),
                        keyPrefix: 'quest_fail',
                        label: 'FAIL',
                        icon: Icons.dangerous_outlined,
                        tone: AppColors.danger,
                        value: _fail,
                        max: teamSize,
                        onIncrement:
                            complete || locked ? null : () => _add(success: false),
                        onDecrement: _fail == 0 || locked
                            ? null
                            : () => _remove(success: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                MedievalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            complete
                                ? failed
                                      ? Icons.cancel_outlined
                                      : Icons.check_circle_outline
                                : Icons.pending_outlined,
                            size: 18,
                            color: complete
                                ? failed
                                      ? AppColors.danger
                                      : AppColors.success
                                : AppColors.mutedGold,
                          ),
                          const SizedBox(width: Space.xs),
                          Expanded(
                            child: Text(
                              complete
                                  ? failed
                                        ? 'This quest fails.'
                                        : 'This quest succeeds.'
                                  : 'Waiting for $remaining '
                                        '${remaining == 1 ? 'card' : 'cards'}.',
                              key: const Key('quest_status'),
                              style: AppText.bodyStrong,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        game.failsRequired == 2
                            ? 'Quest ${game.questNumber} needs two fail cards to '
                                  'fail. One fail card is not enough at this '
                                  'table size.'
                            : 'One fail card fails the quest.',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.md),
                MedievalCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Score(label: 'GOOD', value: game.questSuccesses),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.divider,
                      ),
                      _Score(label: 'EVIL', value: game.questFailures),
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

/// One side of the running quest score.
class _Score extends StatelessWidget {
  const _Score({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppText.caption.copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: Space.xxs),
        Text('$value', style: AppText.numeral.copyWith(fontSize: 28)),
      ],
    );
  }
}
