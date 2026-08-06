/// OR-1030 / OR-434 — Shuffle timeline — calm ritual, peak at completion.
library;

import 'dart:math' show pi, sin;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../theme/tarot_emotional_rhythm.dart';

/// Normalized phase helpers — [t] is master progress 0→1.
abstract final class ShuffleTimeline {
  ShuffleTimeline._();

  static const Duration totalDuration = Duration(milliseconds: 4800);

  static const String alignmentMessage =
      'Kartlar hazırlanıyor…';

  static double _segment(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }

  static double darkenOverlay(double t) {
    return Curves.easeInOutCubic.transform(_segment(t, 0.0, 0.14));
  }

  static double cameraZoom(double t) {
    final p = Curves.easeInOutCubic.transform(_segment(t, 0.06, 0.26));
    return lerpDouble(0.90, 1.12, p)!;
  }

  /// Starts aligned with hero deck, settles to center.
  static double cameraPanY(double t) {
    final p = Curves.easeInOutCubic.transform(_segment(t, 0.06, 0.28));
    return lerpDouble(-42, 0, p)!;
  }

  static double deckLift(double t) {
    final p = Curves.easeOutCubic.transform(_segment(t, 0.14, 0.32));
    return -lerpDouble(0, 28, p)!;
  }

  static double separation(double t) {
    return Curves.easeOutCubic.transform(_segment(t, 0.18, 0.36));
  }

  static double shuffleEnvelope(double t) {
    final p = _segment(t, 0.30, 0.56);
    if (p <= 0) return 0;
    return sin(p * pi);
  }

  static double shufflePhase(double t) {
    return Curves.linear.transform(_segment(t, 0.30, 0.56));
  }

  static double fogIntensity(double t) {
    final base = Curves.easeInOutCubic.transform(_segment(t, 0.38, 0.58));
    final peak = TarotEmotionalRhythm.peakPulse(
      t,
      centre: TarotEmotionalRhythm.shuffleCompletion,
      width: 0.10,
    );
    return (base * 0.72 + peak * 0.28).clamp(0.0, 1.0);
  }

  static double glowPulse(double t) {
    final base = fogIntensity(t);
    final calm = TarotEmotionalRhythm.calmDampen(
      TarotEmotionalRhythm.peakPulse(t, centre: 0.56, width: 0.08),
    );
    return base * calm * (0.68 + sin(t * pi * 4) * 0.12);
  }

  static double particleOrbit(double t) {
    return t * pi * 2.4;
  }

  static double messageOpacity(double t) {
    return Curves.easeInOutCubic.transform(_segment(t, 0.52, 0.60));
  }

  static bool shouldNavigate(double t) => t >= 1.0;
}
