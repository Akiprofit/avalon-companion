import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/artwork.dart';
import '../../core/widgets/avalon_screen.dart';
import '../../core/widgets/game_progress_header.dart';
import '../../core/widgets/medieval_card.dart';
import '../../core/widgets/player_tile.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../game_engine/controllers/game_session_controller.dart';
import '../../game_engine/models/game_state.dart';
import '../../game_engine/models/phase.dart';
import '../../game_engine/rules/avalon_tables.dart';
import '../settings/settings_controller.dart';

/// Screen 07 — the MC records the physical vote.
///
/// The table votes with hands or cards; the phone only counts. Each seat is
/// marked once, approve or reject, so the tally cannot drift from the number of
/// players at the table: every seat is a vote, and every vote is a seat. The
/// engine still refuses a partial total and decides the outcome from the counts.
class VotingScreen extends ConsumerStatefulWidget {
  const VotingScreen({super.key});

  @override
  ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen> {
  /// Seat → approval. A missing seat is still uncounted.
  final Map<int, bool> _votes = {};
  bool _resolving = false;

  /// The vote as it stood when it resolved. It keeps the screen intact behind
  /// the outcome dialog after the phase has already moved on.
  GameState? _frozen;

  int get _approve => _votes.values.where((approve) => approve).length;
  int get _reject => _votes.values.where((approve) => !approve).length;

  /// Sets a seat's vote, or clears it when the same side is tapped again, so a
  /// miscount is corrected by touching the seat that was misheard.
  void _setVote(int seat, bool approve) {
    if (_frozen != null) return;
    setState(() {
      if (_votes[seat] == approve) {
        _votes.remove(seat);
      } else {
        _votes[seat] = approve;
      }
    });
  }

  /// Tapping the row cycles approve → reject → uncounted. The two chips are the
  /// direct way; this is the one-handed way.
  void _cycleVote(int seat) {
    if (_frozen != null) return;
    setState(() {
      final current = _votes[seat];
      if (current == null) {
        _votes[seat] = true;
      } else if (current) {
        _votes[seat] = false;
      } else {
        _votes.remove(seat);
      }
    });
  }

  Future<void> _resolve() async {
    final game = ref.read(gameSessionProvider);
    if (game == null || _resolving) return;
    if (_votes.length != game.playerCount) return;

    final approve = _approve;
    final reject = _reject;

    setState(() {
      _resolving = true;
      _frozen = game;
    });

    final approved = AvalonTables.isApproved(approve, reject);
    final drawLord = ref.read(settingsProvider).kingsDrawnAutomatically;
    final controller = ref.read(gameSessionProvider.notifier);
    controller.recordVotes(approve: approve, reject: reject);
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
    final counted = _votes.length;
    final remaining = game.playerCount - counted;
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
                  trailing: MetaPill(label: '$counted / ${game.playerCount}'),
                ),
                Text(
                  'Mark each player once. A tie rejects the team; five '
                  'rejections in a row end the match for Evil.',
                  style: AppText.caption,
                ),
                const SizedBox(height: Space.sm),
                MedievalCard(
                  padding: const EdgeInsets.all(Space.xs),
                  child: Column(
                    children: [
                      for (final player in game.players) ...[
                        if (player.seat > 1) const SizedBox(height: Space.xxs),
                        PlayerTile(
                          key: Key('vote_seat_${player.seat}'),
                          name: player.name,
                          seat: player.seat,
                          isLeader: player.seat == game.leaderSeat,
                          isSelected: _votes.containsKey(player.seat),
                          onTap: locked ? null : () => _cycleVote(player.seat),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _VoteChip(
                                key: Key('vote_seat_${player.seat}_approve'),
                                icon: Icons.check_rounded,
                                label: 'Approve ${player.name}',
                                tone: AppColors.success,
                                isSelected: _votes[player.seat] == true,
                                onTap: locked
                                    ? null
                                    : () => _setVote(player.seat, true),
                              ),
                              const SizedBox(width: Space.xxs),
                              _VoteChip(
                                key: Key('vote_seat_${player.seat}_reject'),
                                icon: Icons.close_rounded,
                                label: 'Reject ${player.name}',
                                tone: AppColors.danger,
                                isSelected: _votes[player.seat] == false,
                                onTap: locked
                                    ? null
                                    : () => _setVote(player.seat, false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
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
                      const SizedBox(height: Space.sm),
                      Row(
                        children: [
                          _Tally(
                            label: 'Approve',
                            value: _approve,
                            tone: AppColors.success,
                          ),
                          const SizedBox(width: Space.lg),
                          _Tally(
                            label: 'Reject',
                            value: _reject,
                            tone: AppColors.danger,
                          ),
                        ],
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

/// A 48 dp approve/reject target on one seat's row.
class _VoteChip extends StatelessWidget {
  const _VoteChip({
    super.key,
    required this.icon,
    required this.label,
    required this.tone,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: onTap != null,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: isSelected ? tone.withValues(alpha: 0.16) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.chip),
            side: BorderSide(color: isSelected ? tone : AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: kMinTapTarget,
              height: kMinTapTarget,
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? tone : AppColors.mutedText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The running approve / reject count under the status line.
class _Tally extends StatelessWidget {
  const _Tally({required this.label, required this.value, required this.tone});

  final String label;
  final int value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
        ),
        const SizedBox(width: Space.xs),
        Text(
          '$label $value',
          style: AppText.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
