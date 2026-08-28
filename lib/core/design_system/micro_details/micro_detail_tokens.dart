/// EPIC-027 — Timing and intensity tokens for micro visual details.
library;

import 'package:flutter/material.dart';

/// Global micro-motion — nothing perfectly static.
abstract final class MicroDetailTokens {
  MicroDetailTokens._();

  /// Light sweep across cards — 12–20 s, desynchronized per instance.
  static const Duration sweepMin = Duration(seconds: 12);
  static const Duration sweepMax = Duration(seconds: 20);

  /// Ambient breathing for shadows, glow, scale.
  static const Duration breathCycle = Duration(milliseconds: 6800);
  static const Duration iconFloatCycle = Duration(milliseconds: 5200);
  static const Duration buttonGlowCycle = Duration(milliseconds: 4200);

  /// List reveal stagger — 15–25 ms per item.
  static const Duration listStaggerStep = Duration(milliseconds: 20);
  static const Duration listStaggerMin = Duration(milliseconds: 15);
  static const Duration listStaggerMax = Duration(milliseconds: 25);

  /// Micro scale breathing amplitudes.
  static const double cardDepthBreath = 0.003;
  static const double heroScaleBreath = 0.008;
  static const double iconFloatAmplitude = 1.8;

  /// Shadow breathing.
  static const double shadowBreathBlur = 3.5;
  static const double shadowBreathOffset = 1.2;

  /// Sweep / highlight intensities.
  static const double cardSweepIntensity = 0.09;
  static const double cardHighlightIntensity = 0.06;
  static const double buttonSweepIntensity = 0.14;

  /// Background parallax — extremely slow.
  static const Duration parallaxCycle = Duration(seconds: 28);
  static const double parallaxAmplitude = 6;

  /// Desynchronized sweep duration from a seed (widget hash / index).
  static Duration sweepDurationFor(int seed) {
    final span = sweepMax.inMilliseconds - sweepMin.inMilliseconds;
    final offset = (seed.abs() % span);
    return Duration(milliseconds: sweepMin.inMilliseconds + offset);
  }

  static Duration listStaggerFor(int index) {
    final ms = listStaggerMin.inMilliseconds +
        (index * 3) % (listStaggerMax.inMilliseconds - listStaggerMin.inMilliseconds);
    return Duration(milliseconds: ms);
  }
}

/// Curves for organic micro motion.
abstract final class MicroDetailCurve {
  MicroDetailCurve._();

  static const Curve breath = Curves.easeInOutCubic;
  static const Curve sweep = Curves.linear;
}
