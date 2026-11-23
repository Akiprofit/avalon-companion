import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';
import 'button_frame.dart';

/// The single dominant action on a screen — `avalon-ui-system`.
///
/// A struck-gold face: light along the top edge, deep at the foot, and a
/// hairline where the light catches it. It sinks under the thumb.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  static const _face = LinearGradient(
    colors: [AppColors.lightGold, AppColors.gold, AppColors.mutedGold],
    stops: [0, 0.46, 1],
    // Vertical, not diagonal: a wide button lit from above reads as a curved
    // gold face; a diagonal would run out of light halfway across.
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onGold,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20, color: AppColors.onGold),
        if (isLoading || icon != null) const SizedBox(width: Space.xs),
        Flexible(
          child: Text(
            label,
            style: AppText.button.copyWith(color: AppColors.onGold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );

    return SizedBox(
      width: expand ? double.infinity : null,
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: label,
        child: ButtonFrame(
          inkKey: const Key('primary_button_ink'),
          onTap: onPressed,
          enabled: _enabled,
          gradient: _face,
          borderColor: AppColors.hairline,
          // The face sinks, and the content steps down with it.
          pressedPadding: const EdgeInsets.fromLTRB(
            Space.lg,
            2,
            Space.lg,
            0,
          ),
          child: content,
        ),
      ),
    );
  }
}
