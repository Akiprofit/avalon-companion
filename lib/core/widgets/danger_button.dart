import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';

/// The one destructive action of a confirmation, never the default action of a
/// screen — `avalon-ui-system`. Same height and radius as `PrimaryButton`, in
/// the danger colour, so a delete never looks like a save.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(Radii.input),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.input),
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                  child: Center(
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
                            style: AppText.button.copyWith(
                              color: AppColors.parchment,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
