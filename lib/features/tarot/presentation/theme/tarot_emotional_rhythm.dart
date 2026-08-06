/// OR-434 — Emotional memory: peak vs calm contrast across the ritual.
library;

import 'package:flutter/material.dart';

/// Musical rhythm — some moments breathe, some pause, some resolve.
abstract final class TarotEmotionalRhythm {
  TarotEmotionalRhythm._();

  /// Soft bell curve centred on a memorable beat (0–1 timeline).
  static double peakPulse(
    double t, {
    required double centre,
    double width = 0.10,
  }) {
    if (width <= 0) return 0;
    final dist = ((t - centre).abs() / width).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(1 - dist);
  }

  /// Calm inverse — ordinary moments recede when peaks are near.
  static double calmDampen(double peak, {double floor = 0.58}) =>
      (1.0 - peak * 0.42).clamp(floor, 1.0);

  /// Hold plateau — breath before resolution.
  static double holdPlateau(double t, double start, double end) {
    if (t <= start || t >= end) return 0;
    final mid = (start + end) / 2;
    final half = (end - start) / 2;
    final dist = ((t - mid).abs() / half).clamp(0.0, 1.0);
    return Curves.easeInOutCubic.transform(1 - dist);
  }

  // ── Journey peaks (normalized 0–1 within each phase) ─────────────────────

  static const spreadChoice = 0.0; // composition, not animation peak
  static const sacredStillness = 0.72;
  static const revealFlip = 0.84;
  static const readingIntro = 0.48;
  static const readingReflection = 0.82;
  static const shuffleCompletion = 0.56;
}
