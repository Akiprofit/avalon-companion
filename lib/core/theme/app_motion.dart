import 'package:material_ui/material_ui.dart';

/// Motion accessibility helpers — master plan §3.4a.
///
/// Android exposes "Remove animations" through `MediaQuery.disableAnimations`.
/// Every cinematic movement (drift, scale, glow) must check this before running,
/// so the app stays usable for anyone who gets motion sick.

/// True when the platform asks the app to avoid decorative animation.
bool prefersReducedMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// [duration] when motion is allowed, otherwise zero.
///
/// Use for one-shot transitions that should still happen, just instantly.
Duration motionDuration(BuildContext context, Duration duration) =>
    prefersReducedMotion(context) ? Duration.zero : duration;
