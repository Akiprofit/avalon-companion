import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';

/// Content container with an optional gold top rule — `avalon-ui-system`.
class MedievalCard extends StatelessWidget {
  const MedievalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.md),
    this.showTopRule = false,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showTopRule;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTopRule)
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: Space.sm),
            color: AppColors.gold.withValues(alpha: 0.45),
          ),
        Padding(padding: padding, child: child),
      ],
    );

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: borderColor ?? AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}
