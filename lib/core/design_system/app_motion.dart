/// EPIC-021 — Centralized motion: durations, curves, and transitions.
library;

import 'package:flutter/material.dart';

import '../../core/theme/craftsmanship_rhythm.dart';

/// Animation durations.
abstract final class AppMotionDuration {
  AppMotionDuration._();

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 240);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration medium = Duration(milliseconds: 520);
  static const Duration slow = Duration(milliseconds: 680);
  static const Duration breathe = Duration(milliseconds: 4800);
  static const Duration float = Duration(milliseconds: 5600);
  static const Duration shimmer = Duration(milliseconds: 3200);
  static const Duration glowPulse = Duration(milliseconds: 1800);

  // Legacy aliases.
  static const Duration appear = Duration(milliseconds: 420);
  static const Duration scroll = Duration(milliseconds: 320);
  static const Duration pulse = glowPulse;
  static const Duration think = Duration(milliseconds: 2000);
}

/// Shared animation curves.
abstract final class AppMotionCurve {
  AppMotionCurve._();

  static Curve get standard => CraftsmanshipRhythm.curve;
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve spring = Curves.easeOutCubic;
}

/// Reusable transition builders.
abstract final class AppMotion {
  AppMotion._();

  static Animation<double> fade(Animation<double> parent) =>
      CurvedAnimation(parent: parent, curve: AppMotionCurve.easeOut);

  static Animation<Offset> slideUp(Animation<double> parent) {
    return Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: parent, curve: AppMotionCurve.easeOut));
  }

  static Animation<double> scaleIn(Animation<double> parent) {
    return Tween<double>(begin: 0.975, end: 1).animate(
      CurvedAnimation(parent: parent, curve: AppMotionCurve.easeOut),
    );
  }

  static Animation<double> float(AnimationController controller) {
    return Tween<double>(begin: -3.5, end: 3.5).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  static Animation<double> glowPulse(AnimationController controller) {
    return Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }
}

/// Legacy duration export — keeps `AppDuration` imports working.
abstract final class AppDuration {
  AppDuration._();

  static const Duration fast = AppMotionDuration.fast;
  static const Duration normal = AppMotionDuration.normal;
  static const Duration medium = AppMotionDuration.medium;
  static const Duration slow = AppMotionDuration.slow;
  static const Duration breathe = AppMotionDuration.breathe;
  static const Duration appear = AppMotionDuration.appear;
  static const Duration scroll = AppMotionDuration.scroll;
  static const Duration pulse = AppMotionDuration.pulse;
  static const Duration think = AppMotionDuration.think;
}
