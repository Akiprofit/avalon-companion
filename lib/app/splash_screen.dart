import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_info.dart';
import '../core/constants/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_metrics.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_text.dart';
import '../core/theme/artwork.dart';
import '../core/widgets/cinematic_background.dart';

/// Screen 01 — short, elegant opening that hands over to Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) context.goNamed(RouteNames.home);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = prefersReducedMotion(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CinematicBackground(
        imageAsset: Artwork.splash,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(Space.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - Space.lg * 2),
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: motionDuration(context, Motion.dramatic),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: reduced ? 1 : value,
                    child: Transform.scale(
                      scale: reduced ? 1 : 0.94 + 0.06 * value,
                      child: child,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Seal(),
                      const SizedBox(height: Space.xl),
                      const Text('AVALON', style: AppText.display),
                      const SizedBox(height: Space.xs),
                      Text(
                        'COMPANION',
                        style: AppText.caption.copyWith(
                          letterSpacing: 6,
                          color: AppColors.mutedGold,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Space.xxxl),
                      if (reduced)
                        Text(
                          'Preparing the table…',
                          style: AppText.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: AppColors.mutedGold,
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: Space.xl),
        child: Text(
          'v${AppInfo.version}',
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: AppColors.mutedGold),
        ),
      ),
    );
  }
}

/// Shield seal with the same quiet gold aura as the home screen.
class _Seal extends StatelessWidget {
  const _Seal();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 184,
      height: 184,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.18),
                  AppColors.gold.withValues(alpha: 0),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              color: AppColors.surface,
            ),
            child: const Icon(
              Icons.shield_moon_outlined,
              size: 52,
              color: AppColors.lightGold,
            ),
          ),
        ],
      ),
    );
  }
}
