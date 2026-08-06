/// OR-415 — Unified observatory rhythm — one living breath, never static.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import 'home_atmosphere.dart';

/// Master cycle every ambient channel derives from — sacred observatory breath.
abstract final class HomePresenceRhythm {
  HomePresenceRhythm._();

  /// Primary chamber breath — all motion harmonizes to this period.
  static const Duration masterCycle = Duration(seconds: 12);

  static const Curve breathCurve = Curves.easeInOut;

  /// Resume mid-cycle so the screen feels alive before arrival.
  static double clockPhase() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return (ms % masterCycle.inMilliseconds) / masterCycle.inMilliseconds;
  }

  static double _wave(double master, {double frequency = 1.0, double offset = 0.0}) {
    final t = (master * frequency + offset) % 1.0;
    return breathCurve.transform(t);
  }

  /// Hero orb body breath [0, 1].
  static double breathe(double master) => _wave(master);

  /// Orb float — quarter-cycle offset from breathe.
  static double float(double master) => _wave(master, offset: 0.25);

  /// Inner gold luminosity — gentle double-frequency whisper.
  static double innerGlow(double master) => _wave(master, frequency: 2.0, offset: 0.1);

  /// Particle drift along master cycle.
  static double particles(double master) => (master / 6.0) % 1.0;

  static double ringClockwise(double master) =>
      (master / 4.0) % 1.0; // 48s = 4× master

  static double ringCounter(double master) =>
      (master / 5.0 + 0.5) % 1.0; // 60s = 5× master

  /// Atmospheric nebula drift.
  static double atmosphere(double master) =>
      _wave(master, frequency: 0.5, offset: 0.35);

  /// Gold specular travel across crystal — almost invisible [0, 1].
  static double goldSpecular(double master) =>
      0.5 + 0.5 * sin(master * pi * 2);

  /// Purple ambient veil pulse — gentler, more peaceful.
  static double ambientVeil(double master) =>
      0.96 + 0.04 * sin((master + 0.2) * pi * 2);

  /// Emotional warmth channel derived from master breath.
  static double emotionalWarmth(double master) =>
      0.5 + 0.5 * sin((master * 0.5 + 0.12) * pi * 2);

  /// Micro shimmer for crystal surfaces — delegates to atmosphere.
  static double crystalShimmer(double master) =>
      HomeAtmosphere.crystalShimmer(master);

  /// Micro parallax depth factors (pixels per scroll px).
  static double parallaxBackground(double scrollPx) => scrollPx * 0.016;

  static double parallaxAtmosphere(double scrollPx) => scrollPx * 0.009;

  static double parallaxGlass(double scrollPx) => scrollPx * 0.003;

  static double parallaxForeground(double scrollPx) => scrollPx * -0.0015;

  static Offset nebulaDrift(double master, {double amplitude = 2.2}) {
    final angle = master * pi * 2;
    return Offset(
      sin(angle) * amplitude,
      sin(angle + pi * 0.35) * amplitude * 0.55,
    );
  }
}
