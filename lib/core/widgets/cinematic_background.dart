import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Full-bleed cinematic backdrop: an artwork plate, a legibility veil and an
/// optional slow drift.
///
/// Artwork is decoration only. It sits behind the content, never receives
/// pointer events, and falls back to the token gradient when no plate is
/// supplied or the asset fails to load. Drift stops when the user has reduced
/// motion enabled.
class CinematicBackground extends StatefulWidget {
  const CinematicBackground({
    super.key,
    this.child,
    this.imageAsset,
    this.drift = true,
  });

  /// Content drawn above the backdrop. Usually null, because screens sit in a
  /// transparent scaffold above this widget.
  final Widget? child;

  /// Bundled artwork path, for example `Artwork.camelot`.
  final String? imageAsset;

  /// Slow scale drift. Ignored when reduced motion is on.
  final bool drift;

  @override
  State<CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<CinematicBackground>
    with SingleTickerProviderStateMixin {
  /// A single, slow settle rather than a loop: the plate drifts while the MC
  /// opens a screen, then holds still. Looping would repaint forever on a phone
  /// that stays awake for a whole match.
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDrift();
  }

  @override
  void didUpdateWidget(CinematicBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageAsset != widget.imageAsset) {
      _drift.value = 0;
    }
    _syncDrift();
  }

  void _syncDrift() {
    final shouldRun = widget.drift &&
        widget.imageAsset != null &&
        !prefersReducedMotion(context);

    if (!shouldRun) {
      if (_drift.isAnimating) _drift.stop();
      _drift.value = 0;
      return;
    }
    if (_drift.isAnimating || _drift.value > 0) return;
    _drift.forward();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageAsset = widget.imageAsset;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        if (imageAsset == null)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundSecondary,
                  AppColors.background,
                  AppColors.background,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          )
        else ...[
          AnimatedBuilder(
            animation: _drift,
            builder: (context, child) {
              final eased = Curves.easeInOut.transform(_drift.value);
              return Transform.scale(
                scale: 1 + 0.04 * eased,
                child: child,
              );
            },
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              excludeFromSemantics: true,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          // Veil: keeps text legible no matter how bright the artwork is.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.veilTop,
                  AppColors.veilMiddle,
                  AppColors.veilBottom,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ],
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
