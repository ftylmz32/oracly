/// Final motion polish — freeze ambient work when it would feel cheap or jank.
library;

import 'package:flutter/material.dart';

import 'oracly_reduced_motion.dart';

/// Quiet, expensive motion. Ambient loops yield on reduce-motion and mid-range.
abstract final class OraclyQuietMotion {
  OraclyQuietMotion._();

  /// TECNO / Spark-class and similar: HD+ physical short edge, low DPR.
  /// Keeps premium rest pose without perpetual GPU work.
  static bool constrained(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    if (media == null) return false;
    final shortest = media.size.shortestSide;
    final dpr = media.devicePixelRatio;
    if (!dpr.isFinite || dpr <= 0) return false;
    if (dpr <= 2.0 || shortest < 360) return true;
    final physicalShort = shortest * dpr;
    // ~720–960px class (HD+ / mid FHD phones).
    return physicalShort <= 960 || (shortest <= 400 && dpr <= 2.75);
  }

  static bool still(BuildContext context) {
    return OraclyReducedMotion.of(context) || constrained(context);
  }

  static void ambient(
    BuildContext context,
    AnimationController controller, {
    bool reverse = false,
    double rest = 0.5,
  }) {
    if (still(context)) {
      if (controller.isAnimating) controller.stop();
      if (controller.value != rest) controller.value = rest;
      return;
    }
    if (!controller.isAnimating) {
      controller.repeat(reverse: reverse);
    }
  }
}
