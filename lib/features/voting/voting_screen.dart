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
import '../../game_engine/rules/avalon_tables.dart';
import '../settings/settings_controller.dart';

/// Screen 07 — the MC records the physical vote.
///
/// The table votes with hands or cards; the phone only counts. The tallies live
/// in this screen until the vote resolves, because the engine deliberately
/// refuses a partial total: a vote is recorded once, for the whole table.
class VotingScreen extends ConsumerStatefulWidget {
  const VotingScreen({super.key});

  @override
  ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen> {
  int _approve = 0;
  int _reject = 0;
  bool _resolving = false;

  /// The vote as it stood when it resolved. It keeps the screen intact behind
  /// the outcome dialog after the phase has already moved on.
  GameState? _frozen;

  void _add({required bool approve}) {
    final game = ref.read(gameSessionProvider);
    if (game == null) return;
    if (_approve + _reject >= game.playerCount) return;
    setState(() {
      if (approve) {
        _approve++;
      } else {
        _reject++;
      }
    });
  }

  void _remove({required bool approve}) {
    setState(() {
      if (approve) {
        if (_approve > 0) _approve--;
      } else {
        if (_reject > 0) _reject--;
      }
    });
  }

  Future<void> _resolve() async {
    final game = ref.read(gameSessionProvider);
    if (game == null || _resolving) return;
    if (_approve + _reject != game.playerCount) return;

    setState(() {
      _resolving = true;
      _frozen = game;
    });

    final approved = AvalonTables.isApproved(_approve, _reject);
    final drawLord = ref.read(settingsProvider).kingsDrawnAutomatically;
    final controller = ref.read(gameSessionProvider.notifier);
    controller.recordVotes(approve: _approve, reject: _reject);
    controller.resolveTeamVote(drawLord: drawLord);

    final after = ref.read(gameSessionProvider);
    if (!mounted) return;

    final evilWins = after?.phase == Phase.evilVictory;
    final drawsKing = after?.phase == Phase.lordSelection;
    final nextLeader = after?.leader.displayName ?? 'the next player';
    final title = approved
        ? 'The team is approved'
        : evilWins
        ? 'Fifth rejection'
        : 'The team is rejected';
    final message = approved
        ? 'Quest ${game.questNumber} begins. The chosen players now go on '
              'the quest.'
        : evilWins
        ? 'Five proposals were rejected. The table is deadlocked and Evil '
              'wins.'
        : drawsKing
        ? 'The wheel now draws a new King, who will propose the next team.'
        : 'The leader token passes to $nextLeader. The table discusses again.';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message, style: AppText.body),
        actions: [
          TextButton(
            key: const Key('voting_outcome_continue'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Back to the table'),
          ),
        ],
      ),
    );
    if (mounted) {
      context.goNamed(
        drawsKing ? RouteNames.lordSelection : RouteNames.dashboard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(gameSessionProvider);
    final game = _frozen ?? (live?.phase == Phase.teamVoting ? live : null);
    final locked = _frozen != null;

    if (game == null) {
      return AvalonScreen(
        appBar: AppBar(title: const Text('THE VOTE')),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No vote is in progress.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.xs),
              Text(
                'Propose a team from the dashboard first.',
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.lg),
              PrimaryButton(
                key: const Key('voting_none_back'),
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
    final remaining = game.playerCount - _approve - _reject;
    final complete = remaining == 0;
    final currentlyApproved = AvalonTables.isApproved(_approve, _reject);

    return AvalonScreen(
      padded: false,
      backgroundImage: Artwork.voting,
      appBar: AppBar(
        title: const Text('THE VOTE'),
        leading: IconButton(
          key: const Key('voting_back'),
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
          key: const Key('voting_resolve'),
          label: complete
              ? 'Resolve the vote'
              : 'Count ${remaining == 1 ? '1 more vote' : '$remaining more votes'}',
          icon: complete ? Icons.gavel_rounded : Icons.how_to_vote_outlined,
          onPressed: complete && !_resolving && !locked ? _resolve : null,
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
                const SectionHeader(title: 'The proposed team'),
                MedievalCard(
                  child: team.isEmpty
                      ? Text('No team was proposed.', style: AppText.body)
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
                  title: 'The vote',
                  trailing: MetaPill(label: '$_approve / ${game.playerCount}'),
                ),
                Text(
                  'Count the hands. Approvals and rejections must add up to '
                  '${game.playerCount}.',
                  style: AppText.caption,
                ),
                const SizedBox(height: Space.sm),
                Row(
                  children: [
                    Expanded(
                      child: CounterStepper(
                        key: const Key('vote_approve'),
                        keyPrefix: 'vote_approve',
                        label: 'APPROVE',
                        icon: Icons.thumb_up_alt_outlined,
                        tone: AppColors.success,
                        value: _approve,
                        max: game.playerCount,
                        onIncrement: complete || locked ? null : () => _add(approve: true),
                        onDecrement: _approve == 0 || locked
                            ? null
                            : () => _remove(approve: true),
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: CounterStepper(
                        key: const Key('vote_reject'),
                        keyPrefix: 'vote_reject',
                        label: 'REJECT',
                        icon: Icons.thumb_down_alt_outlined,
                        tone: AppColors.danger,
                        value: _reject,
                        max: game.playerCount,
                        onIncrement: complete || locked
                            ? null
                            : () => _add(approve: false),
                        onDecrement: _reject == 0 || locked
                            ? null
                            : () => _remove(approve: false),
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
                                ? currentlyApproved
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined
                                : Icons.pending_outlined,
                            size: 18,
                            color: complete
                                ? currentlyApproved
                                      ? AppColors.success
                                      : AppColors.danger
                                : AppColors.mutedGold,
                          ),
                          const SizedBox(width: Space.xs),
                          Expanded(
                            child: Text(
                              complete
                                  ? currentlyApproved
                                        ? 'This vote approves the team.'
                                        : 'This vote rejects the team.'
                                  : 'Waiting for $remaining '
                                        '${remaining == 1 ? 'vote' : 'votes'}.',
                              key: const Key('voting_status'),
                              style: AppText.bodyStrong,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        'A tie rejects the team. Five rejections in a row end '
                        'the match for Evil.',
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
