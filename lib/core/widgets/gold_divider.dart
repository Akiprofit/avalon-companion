import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';

/// Ornamental separator: hairline with a centred diamond.
class GoldDivider extends StatelessWidget {
  const GoldDivider({super.key, this.padding = const EdgeInsets.symmetric(vertical: Space.md)});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: AppColors.gold.withValues(alpha: 0.4)),
    );
    return Padding(
      padding: padding,
      child: Row(
        children: [
          line,
          const SizedBox(width: Space.xs),
          Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: 6,
              height: 6,
              color: AppColors.mutedGold,
            ),
          ),
          const SizedBox(width: Space.xs),
          line,
        ],
      ),
    );
  }
}
