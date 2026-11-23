import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';
import 'button_frame.dart';

/// Outline action — `avalon-ui-system`.
///
/// Sits one step under the gold action: a dark face, a fine gold rim and a gold
/// icon, so it is clearly a button without competing with the primary one.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.alignment = MainAxisAlignment.center,
  });

  static const _face = LinearGradient(
    colors: [AppColors.surfaceRaised, AppColors.surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: label,
        child: ButtonFrame(
          inkKey: const Key('secondary_button_ink'),
          onTap: onPressed,
          enabled: onPressed != null,
          gradient: _face,
          borderColor: AppColors.mutedGold,
          alignment: expand
              ? Alignment.center
              : switch (alignment) {
                  MainAxisAlignment.start => Alignment.centerLeft,
                  MainAxisAlignment.end => Alignment.centerRight,
                  _ => Alignment.center,
                },
          // The face sinks, and the content steps down with it.
          pressedPadding: const EdgeInsets.fromLTRB(
            Space.lg,
            2,
            Space.lg,
            0,
          ),
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
                  style: AppText.button.copyWith(color: AppColors.parchment),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
