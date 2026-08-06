/// OR-424 / OR-434 — Sacred moment between choosing and knowing.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../theme/tarot_emotional_rhythm.dart';

/// Emotional curve from card choice into revelation — never rushed.
abstract final class SacredMoment {
  SacredMoment._();

  /// One continuous breath — slightly longer hold for emotional memory.
  static const Duration ritualDuration = Duration(milliseconds: 900);

  /// Maps linear animation time to sacred emotional progress (0–1).
  static double progress(double linear) {
    final t = linear.clamp(0.0, 1.0);
    if (t <= 0.32) {
      return Curves.easeInOutCubic.transform(t / 0.32) * 0.62;
    }
    if (t <= 0.82) {
      final hold = (t - 0.32) / 0.50;
      final plateau = TarotEmotionalRhythm.holdPlateau(t, 0.38, 0.78);
      final pulse = sin(hold * pi) * 0.006 * (1 - plateau * 0.85);
      return 0.62 + hold * 0.28 + pulse + plateau * 0.04;
    }
    return 0.94 + Curves.easeInOut.transform((t - 0.82) / 0.18) * 0.06;
  }

  /// Brief breath plateau — interface almost holds still.
  static double breathHold(double linear) {
    if (linear < 0.30 || linear > 0.86) return 0;
    return sin(((linear - 0.30) / 0.56) * pi).clamp(0.0, 1.0);
  }

  /// Chrome yields quickly, then stays quiet during the hold.
  static double chromeFade(double linear) {
    final t = linear.clamp(0.0, 1.0);
    final fade = Curves.easeInCubic.transform((t / 0.28).clamp(0.0, 1.0));
    final hold = breathHold(t);
    return (fade * 0.72 + hold * 0.28).clamp(0.0, 1.0);
  }

  /// Ritual orb light gathers — intentional, not brighter.
  static double orbGather(double linear) {
    final p = progress(linear);
    return Curves.easeInOutCubic.transform(p.clamp(0.0, 1.0));
  }

  /// Deck becomes the gravitational center.
  static double deckFocus(double linear) {
    final p = progress(linear);
    return (p * 0.88 + breathHold(linear) * 0.12).clamp(0.0, 1.0);
  }

  /// Nearby surfaces quietly acknowledge gathered light.
  static double surfaceAcknowledgment(double linear) {
    final p = progress(linear);
    if (p < 0.42) return 0;
    return Curves.easeOutCubic.transform(((p - 0.42) / 0.58).clamp(0.0, 1.0));
  }

  /// Handoff into reveal — destiny continuity, not a cut.
  static double revealHandoff(double linear) {
    if (linear < 0.90) return 0;
    return Curves.easeInOut.transform(((linear - 0.90) / 0.10).clamp(0.0, 1.0));
  }
}
