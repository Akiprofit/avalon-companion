import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';

/// The surface shared by every app button.
///
/// One place for the things a button should never get wrong: the gradient
/// face, the hairline along its edge, the glow that lifts it off the artwork,
/// and a press that sinks it a hair and ripples in gold. Each button only
/// chooses its own colours and content.
class ButtonFrame extends StatefulWidget {
  const ButtonFrame({
    super.key,
    required this.child,
    required this.onTap,
    required this.gradient,
    required this.borderColor,
    this.enabled = true,
    this.glow,
    this.inkKey,
    this.height = 56,
    this.radius = Radii.card,
    this.alignment = Alignment.center,
    this.padding = const EdgeInsets.symmetric(horizontal: Space.lg),
    this.pressedPadding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Gradient gradient;
  final Color borderColor;
  final bool enabled;

  /// Colour of the soft shadow under the face. Null for a quiet button.
  final Color? glow;

  /// Key for the tappable layer, so a test can prove the button reacts.
  final Key? inkKey;

  final double height;
  final double radius;
  final Alignment alignment;
  final EdgeInsets padding;

  /// Padding while the face is sunk. Defaults to [padding]; the extra point is
  /// what makes the press feel like a physical key rather than a colour change.
  final EdgeInsets? pressedPadding;

  @override
  State<ButtonFrame> createState() => _ButtonFrameState();
}

class _ButtonFrameState extends State<ButtonFrame> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final corners = BorderRadius.circular(widget.radius);
    final padding = _pressed
        ? (widget.pressedPadding ?? widget.padding)
        : widget.padding;

    return SizedBox(
      height: widget.height,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.45,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: Motion.micro,
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: corners,
              border: Border.all(color: widget.borderColor),
              boxShadow: [
                if (widget.glow != null)
                  BoxShadow(
                    color: widget.glow!,
                    blurRadius: 20,
                    offset: const Offset(0, 9),
                  ),
              ],
            ),
            child: Stack(
              // `passthrough` keeps the face sized by its content when the
              // button is not expanding: the shine below is positioned, so an
              // all-positioned stack would collapse to the incoming bounds.
              fit: StackFit.passthrough,
              children: [
                Material(
                  color: Colors.transparent,
                  borderRadius: corners,
                  child: InkWell(
                    key: widget.inkKey,
                    borderRadius: corners,
                    onTap: widget.enabled ? widget.onTap : null,
                    onHighlightChanged: (value) =>
                        setState(() => _pressed = value),
                    splashColor: AppColors.goldOverlay,
                    highlightColor: AppColors.goldOverlay,
                    child: Padding(
                      padding: padding,
                      child: Align(
                        alignment: widget.alignment,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
                // The catch of light along the top edge: what makes the face
                // read as struck metal rather than a flat rectangle.
                Positioned(
                  top: 1,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: Container(
                      height: 1.2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.hairlineFade,
                            AppColors.hairline,
                            AppColors.hairlineFade,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
