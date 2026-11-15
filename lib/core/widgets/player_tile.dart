import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';

/// One player seat. Holds public information only — never a character.
class PlayerTile extends StatelessWidget {
  const PlayerTile({
    super.key,
    required this.name,
    required this.seat,
    this.isLeader = false,
    this.isSelected = false,
    this.isDisabled = false,
    this.onTap,
    this.trailing,
  });

  final String name;
  final int seat;
  final bool isLeader;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final active = isSelected && !isDisabled;
    return Semantics(
      button: onTap != null,
      selected: isSelected,
      enabled: !isDisabled,
      label: '${name.trim().isEmpty ? 'Seat $seat' : name}'
          '${isLeader ? ', leader' : ''}',
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1,
        child: Material(
          color: active ? AppColors.surfaceRaised : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card),
            side: BorderSide(
              color: active ? AppColors.gold : AppColors.divider,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.sm,
              ),
              child: Row(
                children: [
                  if (active)
                    Container(
                      width: 3,
                      height: 28,
                      margin: const EdgeInsets.only(right: Space.sm),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  Container(
                    width: 32,
                    height: 32,
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
                      style: AppText.numeral.copyWith(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      name.trim().isEmpty ? 'Seat $seat' : name.trim(),
                      style: AppText.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLeader)
                    const Padding(
                      padding: EdgeInsets.only(right: Space.xs),
                      child: Icon(
                        Icons.workspace_premium_outlined,
                        size: 18,
                        color: AppColors.gold,
                      ),
                    ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
