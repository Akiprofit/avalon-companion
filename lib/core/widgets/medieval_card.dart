import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';

/// Content container with an optional gold top rule — `avalon-ui-system`.
///
/// A card that can be tapped or long-pressed dips slightly and eases back, so
/// the press is acknowledged even before the action behind it starts. Selection
/// is drawn here too: a gold border and the raised surface are the same pair
/// `PlayerTile` uses for a chosen seat.
class MedievalCard extends StatefulWidget {
  const MedievalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.md),
    this.showTopRule = false,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showTopRule;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final Color? borderColor;

  @override
  State<MedievalCard> createState() => _MedievalCardState();
}

class _MedievalCardState extends State<MedievalCard> {
  bool _pressed = false;

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (!_interactive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : Motion.micro;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTopRule)
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: Space.sm),
            color: AppColors.gold.withValues(alpha: 0.45),
          ),
        Padding(padding: widget.padding, child: widget.child),
      ],
    );

    return Semantics(
      selected: widget.isSelected,
      button: _interactive,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : Motion.transition,
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.surfaceRaised
                : AppColors.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.gold
                  : widget.borderColor ?? AppColors.divider,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: _interactive
                ? InkWell(
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    onTapDown: (_) => _setPressed(true),
                    onTapUp: (_) => _setPressed(false),
                    onTapCancel: () => _setPressed(false),
                    child: content,
                  )
                : content,
          ),
        ),
      ),
    );
  }
}
