/// Canonical tarot ritual timing — weight, not speed.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/oracly_reduced_motion.dart';

/// Production motion language for the live tarot ritual.
abstract final class TarotCinematicMotion {
  TarotCinematicMotion._();

  static const Duration micro = Duration(milliseconds: 160);
  static const Duration interaction = Duration(milliseconds: 280);
  static const Duration cardMove = Duration(milliseconds: 560);
  static const Duration draw = Duration(milliseconds: 580);
  static const Duration preFlip = Duration(milliseconds: 240);
  static const Duration flip = Duration(milliseconds: 840);
  static const Duration revealGlow = Duration(milliseconds: 420);
  static const Duration shuffle = Duration(milliseconds: 1240);
  static const Duration majorReveal = Duration(milliseconds: 2480);
  static const Duration chamber = Duration(milliseconds: 1960);
  static const Duration deckIdle = Duration(milliseconds: 6400);
  static const Duration ambient = Duration(milliseconds: 23000);
  static const Duration backNav = Duration(milliseconds: 260);

  /// Physical ease — decelerate with a hair of overshoot.
  static const Curve weight = Cubic(0.22, 0.74, 0.18, 1.0);
  static const Curve settle = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Curve lift = Cubic(0.2, 0.0, 0.0, 1.0);

  /// IEEE-safe unit interval for [Curve.transform] / [Opacity].
  static double unit(double t) => t.clamp(0.0, 1.0);

  /// Never feed Curve.transform a value outside [0, 1].
  static double curve(Curve curve, double t) =>
      curve.transform(unit(t));

  static Duration of(BuildContext context, Duration normal) {
    return OraclyReducedMotion.duration(context, normal);
  }

  static double overshoot(double t, {double amount = 0.012}) {
    final p = curve(Curves.easeOutCubic, t);
    if (p < 0.86) return p;
    final tail = unit((p - 0.86) / 0.14);
    return 1 + amount * (1 - tail) * (1 - 2 * (tail - 0.5).abs());
  }
}
