/// Accessibility — honor OS "reduce motion" / disable animations.
library;

import 'package:flutter/material.dart';

abstract final class OraclyReducedMotion {
  OraclyReducedMotion._();

  /// True when the platform asks for calmer motion.
  static bool of(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return false;
    return mq.disableAnimations || mq.accessibleNavigation;
  }

  /// Zero duration when reduced; otherwise [normal].
  static Duration duration(BuildContext context, Duration normal) {
    return of(context) ? Duration.zero : normal;
  }

  /// One-shot ritual: skip to the end, or start if still idle.
  static void playOnce(BuildContext context, AnimationController controller) {
    if (of(context)) {
      controller.value = 1;
    } else if (controller.status == AnimationStatus.dismissed) {
      controller.forward();
    }
  }

  /// Ambient loop: freeze at rest, or keep breathing.
  static void stillLoop(
    BuildContext context,
    AnimationController controller, {
    bool reverse = false,
    double rest = 0.5,
  }) {
    if (of(context)) {
      if (controller.isAnimating) controller.stop();
      if (controller.value != rest) controller.value = rest;
    } else if (!controller.isAnimating) {
      controller.repeat(reverse: reverse);
    }
  }
}
