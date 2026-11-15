import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';
import 'avalon_icon_button.dart';

/// Large labelled tally with −/+ controls, used for physical votes and, later,
/// quest success/fail cards.
///
/// The value is owned by the caller and never counted here, so the screen and
/// the rule engine stay the single source of truth. Buttons disable at the
/// bounds instead of silently clamping.
class CounterStepper extends StatelessWidget {
  const CounterStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    required this.keyPrefix,
    this.tone = AppColors.parchment,
    this.icon,
    this.min = 0,
    this.max,
  });

  final String label;
  final int value;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  /// Prefix for the inner control keys, for example `vote_approve` gives
  /// `vote_approve_increment`, `vote_approve_decrement` and `vote_approve_value`.
  final String keyPrefix;

  final Color tone;
  final IconData? icon;
  final int min;
  final int? max;

  @override
  Widget build(BuildContext context) {
    final canDecrement = value > min;
    final canIncrement = max == null || value < max!;

    return Semantics(
      container: true,
      label: label,
      value: '$value',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.sm,
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: tone),
                      const SizedBox(width: Space.xxs),
                    ],
                    Text(
                      label,
                      style: AppText.sectionTitle.copyWith(color: tone),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                '$value',
                key: Key('${keyPrefix}_value'),
                style: AppText.numeral.copyWith(fontSize: 40, color: tone),
              ),
              const SizedBox(height: Space.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AvalonIconButton(
                    key: Key('${keyPrefix}_decrement'),
                    icon: Icons.remove_rounded,
                    semanticLabel: 'Remove one from $label',
                    onPressed: canDecrement ? onDecrement : null,
                    size: kMinTapTarget,
                  ),
                  const SizedBox(width: Space.lg),
                  AvalonIconButton(
                    key: Key('${keyPrefix}_increment'),
                    icon: Icons.add_rounded,
                    semanticLabel: 'Add one to $label',
                    onPressed: canIncrement ? onIncrement : null,
                    size: kMinTapTarget,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
