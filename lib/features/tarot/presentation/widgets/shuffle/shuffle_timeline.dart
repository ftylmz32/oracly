/// Six-phase ritual shuffle — lift, part, interleave, trail, close, settle.
library;

import 'dart:math' show pi, sin;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../motion/tarot_cinematic_motion.dart';
import '../../theme/tarot_emotional_rhythm.dart';

abstract final class ShuffleTimeline {
  ShuffleTimeline._();

  static const Duration totalDuration = TarotCinematicMotion.shuffle;

  static double _segment(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    // Division near the end can land slightly above 1.0 in IEEE float.
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  static double darkenOverlay(double t) {
    return TarotCinematicMotion.curve(Curves.easeInOutCubic, _segment(t, 0.0, 0.12));
  }

  static double cameraZoom(double t) {
    final p = TarotCinematicMotion.curve(TarotCinematicMotion.weight, _segment(t, 0.04, 0.22));
    return lerpDouble(1.0, 1.018, p)!;
  }

  static double cameraPanY(double t) {
    final p = TarotCinematicMotion.curve(TarotCinematicMotion.weight, _segment(t, 0.04, 0.24));
    return lerpDouble(-10, 0, p)!;
  }

  static double deckLift(double t) {
    final up = TarotCinematicMotion.curve(Curves.easeOutCubic, _segment(t, 0.0, 0.16));
    final down = TarotCinematicMotion.curve(Curves.easeInOutCubic, _segment(t, 0.78, 1.0));
    return -lerpDouble(0, 14, up)! * (1 - down * 0.92);
  }

  static double separation(double t) {
    final open = TarotCinematicMotion.curve(Curves.easeOutCubic, _segment(t, 0.10, 0.24));
    final close = TarotCinematicMotion.curve(Curves.easeInOutCubic, _segment(t, 0.58, 0.82));
    return (open * (1 - close) * 0.26).clamp(0.0, 0.28);
  }

  static double shuffleEnvelope(double t) {
    final p = _segment(t, 0.22, 0.62);
    if (p <= 0) return 0;
    return sin(p * pi);
  }

  static double shufflePhase(double t) {
    return TarotCinematicMotion.curve(Curves.easeInOutCubic, _segment(t, 0.22, 0.62));
  }

  static double trail(double t) {
    final p = _segment(t, 0.28, 0.56);
    if (p <= 0) return 0;
    return sin(p * pi) * 0.55;
  }

  static double fogIntensity(double t) {
    final base = TarotCinematicMotion.curve(Curves.easeInOutCubic, _segment(t, 0.16, 0.58));
    final peak = TarotEmotionalRhythm.peakPulse(t, centre: 0.52, width: 0.12);
    return (base * 0.62 + peak * 0.22).clamp(0.0, 1.0);
  }

  static double glowPulse(double t) {
    return fogIntensity(t) * 0.82 + trail(t) * 0.18;
  }

  static double particleOrbit(double t) {
    return t * pi * 0.55;
  }

  static double messageOpacity(double t) {
    return TarotCinematicMotion.curve(Curves.easeInOutCubic, _segment(t, 0.72, 0.88));
  }

  static double settleScale(double t) {
    final p = _segment(t, 0.82, 1.0);
    if (p <= 0) return 1;
    return TarotCinematicMotion.overshoot(p, amount: 0.008);
  }

  static bool shouldNavigate(double t) => t >= 1.0;
}
