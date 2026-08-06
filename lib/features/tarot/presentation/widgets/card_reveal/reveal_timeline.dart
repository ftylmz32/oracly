/// OR-1050+ / OR-430 / OR-434 — Ceremonial reveal timeline — contrast & memory.
library;

import 'dart:math' show cos, pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/tarot_emotional_rhythm.dart';

abstract final class RevealTimeline {
  RevealTimeline._();

  /// Total sequence — hold, turn, absorb, then quietly offer next step.
  static const Duration totalDuration = Duration(milliseconds: 3600);

  /// Normalized flip window — card stays hidden until this begins.
  static const double flipStart = 0.56;
  static const double flipEnd = 0.84;

  static double _seg(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }

  static double darken(double t) =>
      Curves.easeIn.transform(_seg(t, 0.0, 0.20));

  /// Pre-flip stillness — peaks during the hold before the flip.
  static double anticipationStillness(double t) {
    if (t >= flipStart) {
      return (1 - _seg(t, flipStart, flipStart + 0.05)).clamp(0.0, 1.0);
    }
    final build = Curves.easeInOutCubic.transform(_seg(t, 0.08, 0.36));
    final hold = 1 - Curves.easeIn.transform(_seg(t, 0.36, flipStart));
    final plateau = TarotEmotionalRhythm.holdPlateau(t, 0.40, flipStart);
    return (build * 0.42 + hold * 0.48 + plateau * 0.10).clamp(0.0, 1.0);
  }

  /// Ambient motion dampening — quieter as revelation approaches.
  static double ambientCalm(double t) =>
      Curves.easeInOutCubic.transform(_seg(t, 0.06, flipStart));

  /// Background deepens softly as the card turns — never flashes.
  static double ambientDeepen(double t) {
    final hold = Curves.easeInOutCubic.transform(_seg(t, 0.12, flipStart));
    final turn = Curves.easeInOutCubic.transform(_seg(t, flipStart, flipEnd + 0.06));
    return (hold * 0.35 + turn * 0.65).clamp(0.0, 1.0);
  }

  /// Particle drift — slows during hold, gently returns after flip.
  static double particleDrift(double t) {
    final calm = ambientCalm(t);
    final peak = TarotEmotionalRhythm.peakPulse(
      t,
      centre: flipEnd,
      width: 0.12,
    );
    if (t < flipStart) {
      return lerpDouble(1.0, 0.38, calm)!;
    }
    final settle = Curves.easeOutCubic.transform(_seg(t, flipStart, flipEnd + 0.10));
    return lerpDouble(0.38 + peak * 0.22, 0.62, settle)!;
  }

  /// Hero-orb focus — tightens light on the card during the hold.
  static double orbFocus(double t) {
    final hold = anticipationStillness(t);
    final pre = Curves.easeInOutCubic.transform(_seg(t, 0.14, 0.42));
    return (hold * 0.78 + pre * 0.22).clamp(0.0, 1.0);
  }

  /// Competing chrome fades before the card commands attention.
  static double competingFade(double t) =>
      1 - Curves.easeInCubic.transform(_seg(t, 0.06, flipStart));

  static double cameraZoom(double t) {
    final approach = Curves.easeOutCubic.transform(_seg(t, 0.06, 0.30));
    final hold = _seg(t, 0.30, flipStart);
    final preFlip = Curves.easeInOut.transform(_seg(t, flipStart - 0.05, flipStart));
    final peak = TarotEmotionalRhythm.peakPulse(t, centre: flipEnd, width: 0.10);
    final approachZoom = lerpDouble(1.0, 1.10, approach)!;
    final holdZoom = lerpDouble(1.10, 1.12, hold)!;
    final breathe = lerpDouble(holdZoom, 1.13, preFlip)!;
    if (t < flipStart) return t < 0.30 ? approachZoom : breathe;
    if (t < flipEnd + 0.06) {
      return lerpDouble(1.13, 1.14 + peak * 0.02, _seg(t, flipStart, flipEnd + 0.06))!;
    }
    final settle = Curves.easeOutCubic.transform(_seg(t, flipEnd + 0.06, 0.90));
    return lerpDouble(1.14, 1.10, settle)!;
  }

  static double floatUp(double t) {
    final p = Curves.easeOutCubic.transform(_seg(t, 0.08, 0.34));
    final hold = sin(_seg(t, 0.34, flipStart) * pi) * 1.2;
    return -lerpDouble(0, 36, p)! + hold;
  }

  static double floatIdle(double t) {
    if (t < flipEnd + 0.02) return 0;
    return sin((t - flipEnd - 0.02) * pi * 4) * 1.2 * (1 - _seg(t, flipEnd + 0.02, 0.96));
  }

  static double tilt3D(double t) {
    final p = Curves.easeInOutCubic.transform(_seg(t, flipStart - 0.06, flipStart + 0.20));
    return sin(p * pi) * 0.10;
  }

  static double perspectiveTiltY(double t) {
    final p = Curves.easeInOut.transform(_seg(t, flipStart - 0.03, flipStart + 0.24));
    return sin(p * pi) * 0.05;
  }

  /// Deliberate, inevitable rotation — smooth sine ease, never snappy.
  static double flipRotation(double t) {
    final p = _seg(t, flipStart, flipEnd);
    return (0.5 - 0.5 * cos(p * pi)) * pi;
  }

  /// OR-430 — no flash; kept for API compatibility.
  static double flash(double t) => 0;

  /// OR-430 — no burst; particles drift quietly throughout.
  static double flipBurst(double t) => 0;

  static double borderEnergy(double t) =>
      Curves.easeOutCubic.transform(_seg(t, flipEnd + 0.02, flipEnd + 0.18));

  static double landScale(double t) {
    if (t < flipEnd) return 1.0;
    final p = Curves.easeOutCubic.transform(_seg(t, flipEnd, flipEnd + 0.08));
    return lerpDouble(1.006, 1.0, p)!;
  }

  /// Gold frame emerges as the card completes its turn.
  static double frontGoldOpacity(double t) =>
      Curves.easeOutCubic.transform(_seg(t, flipEnd - 0.03, flipEnd + 0.05));

  /// Illustration follows the gold — the memorable beat.
  static double frontArtOpacity(double t) {
    final base = Curves.easeOutCubic.transform(_seg(t, flipEnd + 0.02, flipEnd + 0.16));
    final peak = TarotEmotionalRhythm.peakPulse(t, centre: flipEnd + 0.08, width: 0.08);
    return (base + peak * 0.08).clamp(0.0, 1.0);
  }

  /// Legacy bloom alias — maps to art emergence.
  static double frontBloom(double t) => frontArtOpacity(t);

  static double shadowDepth(double t) =>
      Curves.easeOutCubic.transform(_seg(t, 0.10, flipEnd));

  static double fogRichness(double t) {
    final calm = ambientCalm(t);
    final build = Curves.easeInOutCubic.transform(_seg(t, 0.04, flipStart - 0.04));
    final deepen = ambientDeepen(t) * 0.35;
    return (build * lerpDouble(0.52, 0.24, calm)! + deepen).clamp(0.0, 1.0);
  }

  static double particleSpeed(double t) => particleDrift(t);

  static double glowBehind(double t) {
    final focus = orbFocus(t);
    final deepen = ambientDeepen(t);
    final peak = TarotEmotionalRhythm.peakPulse(t, centre: flipEnd, width: 0.11);
    final base = (focus * 0.54 + deepen * 0.46).clamp(0.0, 1.0);
    return (base + peak * 0.18).clamp(0.0, 1.0);
  }

  /// Title is last — after gold and illustration have settled.
  static double nameOpacity(double t) =>
      Curves.easeOutCubic.transform(_seg(t, flipEnd + 0.12, flipEnd + 0.26));

  static double badgeOpacity(double t) =>
      Curves.easeOutCubic.transform(_seg(t, flipEnd + 0.18, flipEnd + 0.30));

  static double subtitleOpacity(double t) =>
      Curves.easeOutCubic.transform(_seg(t, flipEnd + 0.16, flipEnd + 0.28));

  /// Continue appears once the card has turned — no long absorption wait.
  static double buttonOpacity(double t) =>
      Curves.easeOutCubic.transform(_seg(t, flipEnd + 0.06, flipEnd + 0.22));

  static double buttonSlide(double t) =>
      Curves.easeOutCubic.transform(_seg(t, flipEnd + 0.06, flipEnd + 0.22));

  /// Legacy alias for screen enter darken.
  static double metaOpacity(double t) => nameOpacity(t);
}
