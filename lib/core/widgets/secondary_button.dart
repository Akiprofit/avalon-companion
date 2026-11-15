import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';

/// Outline action — `avalon-ui-system`.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.alignment = MainAxisAlignment.center,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 52,
      width: expand ? double.infinity : null,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('secondary_button_ink'),
              borderRadius: BorderRadius.circular(Radii.input),
              onTap: onPressed,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.input),
                  border: Border.all(color: AppColors.gold, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: alignment,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: AppColors.gold),
                      const SizedBox(width: Space.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: AppText.button.copyWith(
                          color: AppColors.parchment,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
