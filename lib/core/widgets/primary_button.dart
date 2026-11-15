import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';

/// The single dominant action on a screen — `avalon-ui-system`.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final child = Row(
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
      height: 52,
      width: expand ? double.infinity : null,
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: label,
        child: Opacity(
          opacity: _enabled ? 1 : 0.4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.mutedGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Radii.input),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('primary_button_ink'),
                borderRadius: BorderRadius.circular(Radii.input),
                onTap: _enabled ? onPressed : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                  child: Center(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
