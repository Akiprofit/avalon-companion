import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';
import 'button_frame.dart';

/// The one destructive action of a confirmation, never the default action of a
/// screen — `avalon-ui-system`. Same face treatment as `PrimaryButton`, in the
/// danger colour, so a delete never looks like a save.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  static const _face = LinearGradient(
    colors: [AppColors.danger, AppColors.dangerDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: ButtonFrame(
        onTap: onPressed,
        enabled: onPressed != null,
        gradient: _face,
        borderColor: AppColors.hairline,
        glow: AppColors.dangerGlow,
        // The face sinks, and the content steps down with it.
        pressedPadding: const EdgeInsets.fromLTRB(
          Space.lg,
          2,
          Space.lg,
          0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.parchment),
              const SizedBox(width: Space.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: AppText.button.copyWith(color: AppColors.parchment),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
