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
import '../settings/settings_controller.dart';

/// Screen 11 — the MC picks the quest team from the table.
///
/// The selection is seats only. Nothing here knows or asks which character a
/// player holds; the rule engine checks the team size before accepting it.
class TeamSelectionScreen extends ConsumerStatefulWidget {
  const TeamSelectionScreen({super.key});

  @override
  ConsumerState<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends ConsumerState<TeamSelectionScreen> {
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(gameSessionProvider.notifier).beginTeamSelection();
    });
  }

  void _toggleSeat(int seat, int required) {
    setState(() {
      if (!_selected.remove(seat) && _selected.length < required) {
        _selected.add(seat);
      }
    });
  }

  void _confirm() {
    final game = ref.read(gameSessionProvider);
    if (game == null) return;
    final seats = _selected.toList()..sort();
    // House rule: with the approval vote off, the team goes straight to the
    // quest. The engine refuses a team of the wrong size either way.
    final skipVote = !ref.read(settingsProvider).teamVoteEnabled;
    ref
        .read(gameSessionProvider.notifier)
        .proposeTeam(seats, skipVote: skipVote);
    context.goNamed(
      skipVote ? RouteNames.questResolution : RouteNames.dashboard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameSessionProvider);
    if (game == null) {
      return const AvalonScreen(child: SizedBox.shrink());
    }

    final required = game.requiredTeamSize;
    final chosen = _selected.length;
    final complete = chosen == required;
    final canAddMore = chosen < required;
    final voteOff = !ref.watch(settingsProvider.select((s) => s.teamVoteEnabled));

    return AvalonScreen(
      padded: false,
      backgroundImage: Artwork.teamSelection,
      appBar: AppBar(
        title: const Text('CHOOSE THE TEAM'),
        leading: IconButton(
          key: const Key('team_selection_back'),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              key: const Key('team_selection_confirm'),
              label: complete
                  ? 'Confirm the team'
                  : 'Choose $required ${required == 1 ? 'player' : 'players'}',
              icon: Icons.check_rounded,
              onPressed: complete ? _confirm : null,
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          GameProgressHeader(
            leaderName: game.leader.displayName,
            questNumber: game.questNumber,
            requiredTeamSize: required,
            rejectionCount: game.rejectionCount,
            showRejections: !voteOff,
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
                MedievalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quest ${game.questNumber} needs $required '
                        '${required == 1 ? 'player' : 'players'} on the team.',
                        style: AppText.body,
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        canAddMore
                            ? 'Tap the seats the leader puts forward.'
                            : 'Deselect a seat to change the team.',
                        style: AppText.caption,
                      ),
                      if (voteOff) ...[
                        const SizedBox(height: Space.xs),
                        Text(
                          'The approval vote is off: this team goes straight to '
                          'the quest.',
                          key: const Key('team_selection_vote_off'),
                          style: AppText.caption.copyWith(
                            color: AppColors.mutedGold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
                SectionHeader(
                  title: 'The round table',
                  trailing: MetaPill(label: '$chosen / $required'),
                ),
                MedievalCard(
                  padding: const EdgeInsets.all(Space.xs),
                  child: Column(
                    children: [
                      for (final player in game.players) ...[
                        if (player.seat > 1) const SizedBox(height: Space.xxs),
                        PlayerTile(
                          key: Key('team_selection_seat_${player.seat}'),
                          name: player.name,
                          seat: player.seat,
                          isLeader: player.seat == game.leaderSeat,
                          isSelected: _selected.contains(player.seat),
                          onTap: () => _toggleSeat(player.seat, required),
                          trailing: _selected.contains(player.seat)
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: AppColors.gold,
                                )
                              : null,
                        ),
                      ],
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
