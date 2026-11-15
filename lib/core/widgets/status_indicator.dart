import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';

enum StatusTone { idle, active, success, danger }

/// Small dot + word indicator for the current phase or status.
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.label,
    this.tone = StatusTone.idle,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      StatusTone.idle => AppColors.mutedText,
      StatusTone.active => AppColors.gold,
      StatusTone.success => AppColors.success,
      StatusTone.danger => AppColors.danger,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xxs + 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(Radii.chip),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Space.xs),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                color: color,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
