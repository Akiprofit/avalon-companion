import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';

/// Toolbar/utility action. Named `AvalonIconButton` to avoid colliding with
/// Material's `IconButton`; it is the `IconButton` entry of master plan §3.4.
class AvalonIconButton extends StatelessWidget {
  const AvalonIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tooltip,
    this.size = kMinTapTarget,
    this.isActive = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: isActive ? AppColors.surfaceRaised : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.chip),
          side: BorderSide(
            color: isActive ? AppColors.mutedGold : Colors.transparent,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.chip),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: enabled || isActive
                  ? AppColors.gold
                  : AppColors.mutedText.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: tooltip == null ? button : Tooltip(message: tooltip!, child: button),
    );
  }
}
