import 'package:material_ui/material_ui.dart';

import '../../game_engine/models/player.dart';
import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';

/// The whole table at a glance: one compact tile per seat.
///
/// Two columns on every screen size — the phone layout, unchanged on a tablet,
/// where the 600 dp column keeps the tiles the same size.
class PlayerGrid extends StatelessWidget {
  const PlayerGrid({
    super.key,
    required this.players,
    this.leaderSeat,
    this.selectedSeats = const {},
    this.onTap,
  });

  final List<Player> players;
  final int? leaderSeat;

  /// Seats on the current quest team, marked in gold.
  final Set<int> selectedSeats;

  /// Tapping a seat, when the screen has something to do with it.
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Space.xxs,
        crossAxisSpacing: Space.xxs,
        mainAxisExtent: 56,
      ),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return PlayerSeatTile(
          key: Key('round_table_seat_${player.seat}'),
          name: player.displayName,
          seat: player.seat,
          isLeader: player.seat == leaderSeat,
          isSelected: selectedSeats.contains(player.seat),
          onTap: onTap == null ? null : () => onTap!(player.seat),
        );
      },
    );
  }
}

/// One seat: its number, its public name, the leader crown and the team mark.
class PlayerSeatTile extends StatelessWidget {
  const PlayerSeatTile({
    super.key,
    required this.name,
    required this.seat,
    this.isLeader = false,
    this.isSelected = false,
    this.onTap,
  });

  final String name;
  final int seat;
  final bool isLeader;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label:
          '$name${isLeader ? ', leader' : ''}'
          '${isSelected ? ', on the quest team' : ''}',
      child: Material(
        color: isSelected ? AppColors.surfaceRaised : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(
            color: isSelected ? AppColors.gold : AppColors.divider,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLeader ? AppColors.gold : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    '$seat',
                    style: AppText.numeral.copyWith(fontSize: 12),
                  ),
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(
                    name,
                    style: AppText.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLeader)
                  const Icon(
                    Icons.workspace_premium_outlined,
                    size: 17,
                    color: AppColors.gold,
                  )
                else if (isSelected)
                  const Icon(
                    Icons.groups_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
