/// OR-1050+ / OR-430 / OR-434 — Ceremonial reveal timeline — contrast & memory.
library;

import 'dart:math' show pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/tarot_emotional_rhythm.dart';
import '../../../motion/tarot_cinematic_motion.dart';

abstract final class RevealTimeline {
  RevealTimeline._();

  /// Total sequence — pause, focus, flip, reveal, settle.
  static const Duration totalDuration = TarotCinematicMotion.majorReveal;

  /// Beat markers (normalized).
  static const double pauseEnd = 0.12;
  static const double flipStart = 0.20;
  static const double flipEnd = 0.54;
  static const double revealEnd = 0.74;

  /// Resting pile Y — chosen card starts here, then rises.
  static const double deckRestY = 56;

  static double _seg(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    // Division near the end can land slightly above 1.0 in IEEE float.
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  static double darken(double t) =>
      TarotCinematicMotion.curve(Curves.easeIn, _seg(t, 0.0, pauseEnd + 0.06));

  /// Pre-flip stillness — clear pause beat before focus peaks.
  static double anticipationStillness(double t) {
    if (t >= flipStart) {
      return (1 - _seg(t, flipStart, flipStart + 0.04)).clamp(0.0, 1.0);
    }
    final pause = TarotCinematicMotion.curve(
      Curves.easeOutCubic,
      _seg(t, 0.02, pauseEnd),
    );
    final hold = TarotEmotionalRhythm.holdPlateau(t, pauseEnd, flipStart);
    final focus = TarotCinematicMotion.curve(
      Curves.easeInOutCubic,
      _seg(t, pauseEnd, flipStart),
    );
    return (pause * 0.38 + hold * 0.34 + focus * 0.42).clamp(0.0, 1.0);
  }

  /// Ambient motion dampening — quieter as revelation approaches.
  static double ambientCalm(double t) => TarotCinematicMotion.curve(
    Curves.easeInOutCubic,
    _seg(t, 0.04, flipStart),
  );

  /// Background deepens softly as the card turns — never flashes.
  static double ambientDeepen(double t) {
    final hold = TarotCinematicMotion.curve(
      Curves.easeInOutCubic,
      _seg(t, pauseEnd, flipStart),
    );
    final turn = TarotCinematicMotion.curve(
      Curves.easeInOutCubic,
      _seg(t, flipStart, flipEnd + 0.06),
    );
    return (hold * 0.40 + turn * 0.55).clamp(0.0, 1.0);
  }

  /// Soft chamber light — focus before flip, warm after reveal, then settle.
  static double atmosphericLight(double t) {
    final focus = TarotCinematicMotion.curve(
      Curves.easeInOutCubic,
      _seg(t, pauseEnd, flipStart),
    );
    final edge = sin(flipRotation(t)).abs();
    final reveal = TarotCinematicMotion.curve(
      Curves.easeOutCubic,
      _seg(t, flipEnd, flipEnd + 0.16),
    );
    final settle = TarotCinematicMotion.curve(
      Curves.easeOutCubic,
      _seg(t, revealEnd, 0.94),
    );
    final pool = focus * 0.62 + reveal * 0.55;
    return (pool * (1 - edge * 0.28) * (1 - settle * 0.38)).clamp(0.0, 1.0);
  }

  /// Particle drift — slows during pause/focus, gently returns after flip.
  static double particleDrift(double t) {
    final calm = ambientCalm(t);
    if (t < flipStart) {
      return lerpDouble(0.85, 0.28, calm)!;
    }
    final settle = TarotCinematicMotion.curve(
      Curves.easeOutCubic,
      _seg(t, flipStart, revealEnd),
    );
    return lerpDouble(0.28, 0.48, settle)!;
  }

  /// Hero-orb focus — tightens light on the card during the focus beat.
  static double orbFocus(double t) {
    final hold = anticipationStillness(t);
    final pre = TarotCinematicMotion.curve(
      Curves.easeInOutCubic,
      _seg(t, pauseEnd, flipStart),
    );
    final after =
        1 -
        TarotCinematicMotion.curve(
          Curves.easeOutCubic,
          _seg(t, flipEnd, revealEnd),
        );
    return (hold * 0.72 + pre * 0.28 + after * 0.08).clamp(0.0, 1.0);
  }

  /// Competing chrome fades before the card commands attention.
  static double competingFade(double t) =>
      1 -
      TarotCinematicMotion.curve(Curves.easeInCubic, _seg(t, 0.04, flipStart));

  static double cameraZoom(double t) {
    final pause = TarotCinematicMotion.curve(
      Curves.easeOutCubic,
      _seg(t, 0.0, pauseEnd),
    );
    final focus = TarotCinematicMotion.curve(
      Curves.easeInOutCubic,
      _seg(t, pauseEnd, flipStart),
    );
    final turn = _seg(t, flipStart, flipEnd);
    final settle = TarotCinematicMotion.curve(
      TarotCinematicMotion.settle,
      _seg(t, flipEnd + 0.04, 0.90),
    );
    if (t < pauseEnd) return lerpDouble(1.0, 1.012, pause)!;
    if (t < flipStart) return lerpDouble(1.012, 1.022, focus)!;
    if (t < flipEnd) return lerpDouble(1.022, 1.026, turn)!;
    return lerpDouble(1.026, 1.010, settle)!;
  }

  static double floatUp(double t) {
    final p = TarotCinematicMotion.curve(
      TarotCinematicMotion.lift,
      _seg(t, 0.0, pauseEnd),
    );
    return lerpDouble(deckRestY, -14, p)!;
  }

  /// Resting pile fades as the chosen card rises.
  static double originDeckOpacity(double t) =>
      (1 - TarotCinematicMotion.curve(Curves.easeInCubic, _seg(t, 0.18, 0.55)))
          .clamp(0.0, 1.0);

  static double floatIdle(double t) => 0;

  static double tilt3D(double t) {
    final p = TarotCinematicMotion.curve(
      Curves.easeInOutCubic,
      _seg(t, flipStart - 0.06, flipStart + 0.20),
    );
    return sin(p * pi) * 0.07;
  }

  static double perspectiveTiltY(double t) {
    final p = TarotCinematicMotion.curve(
      Curves.easeInOut,
      _seg(t, flipStart - 0.03, flipStart + 0.24),
    );
    return sin(p * pi) * 0.035;
  }

  /// Deliberate rotation — soft weight in, soft land; never snappy.
  static double flipProgress(double p) {
    final u = p.clamp(0.0, 1.0);
    if (u < 0.5) {
      return 0.5 *
          TarotCinematicMotion.curve(
            TarotCinematicMotion.weight,
            (u * 2).clamp(0.0, 1.0),
          );
    }
    return 0.5 +
        0.5 *
            TarotCinematicMotion.curve(
              TarotCinematicMotion.settle,
              ((u - 0.5) * 2).clamp(0.0, 1.0),
            );
  }

  /// Depth through the turn — card thins at 90°.
  static double flipDepth(double t) {
    return sin(flipRotation(t)) * 14;
  }

  static double flipRotation(double t) {
    final p = _seg(t, flipStart, flipEnd);
    return flipProgress(p) * pi;
  }

  /// OR-430 — no flash; kept for API compatibility.
  static double flash(double t) => 0;

  /// OR-430 — no burst; particles drift quietly throughout.
  static double flipBurst(double t) => 0;

  static double borderEnergy(double t) =>
      TarotCinematicMotion.curve(
        Curves.easeOutCubic,
        _seg(t, flipEnd + 0.02, flipEnd + 0.20),
      ) *
      0.72;

  static double landScale(double t) {
    if (t < flipEnd) return 1.0;
    final land = TarotCinematicMotion.curve(
      TarotCinematicMotion.settle,
      _seg(t, flipEnd, flipEnd + 0.08),
    );
    final settle = TarotCinematicMotion.curve(
      Curves.easeOutCubic,
      _seg(t, flipEnd + 0.08, revealEnd),
    );
    return lerpDouble(1.008, 1.0, land)! *
        lerpDouble(1.0, 0.998, settle * 0.28)!;
  }

  /// Gold frame emerges as the card completes its turn.
  static double frontGoldOpacity(double t) => TarotCinematicMotion.curve(
    Curves.easeOutCubic,
    _seg(t, flipEnd - 0.02, flipEnd + 0.08),
  );

  /// Illustration follows the gold — the memorable beat.
  static double frontArtOpacity(double t) {
    final base = TarotCinematicMotion.curve(
      Curves.easeOutCubic,
      _seg(t, flipEnd + 0.02, flipEnd + 0.18),
    );
    return base.clamp(0.0, 1.0);
  }

  /// Legacy bloom alias — maps to art emergence.
  static double frontBloom(double t) => frontArtOpacity(t);

  static double shadowDepth(double t) => TarotCinematicMotion.curve(
    Curves.easeOutCubic,
    _seg(t, pauseEnd, flipEnd),
  );

  static double fogRichness(double t) {
    final calm = ambientCalm(t);
    final build = TarotCinematicMotion.curve(
      Curves.easeInOutCubic,
      _seg(t, 0.02, pauseEnd),
    );
    final deepen = ambientDeepen(t) * 0.28;
    return (build * lerpDouble(0.42, 0.20, calm)! + deepen).clamp(0.0, 1.0);
  }

  static double particleSpeed(double t) => particleDrift(t);

  static double glowBehind(double t) {
    final focus = orbFocus(t);
    final light = atmosphericLight(t);
    final deepen = ambientDeepen(t);
    return (focus * 0.42 + light * 0.38 + deepen * 0.28).clamp(0.0, 1.0);
  }

  /// Title settles first — then continue appears.
  static double nameOpacity(double t) => TarotCinematicMotion.curve(
    Curves.easeOutCubic,
    _seg(t, flipEnd + 0.12, revealEnd),
  );

  static double badgeOpacity(double t) => TarotCinematicMotion.curve(
    Curves.easeOutCubic,
    _seg(t, flipEnd + 0.20, revealEnd + 0.06),
  );

  static double subtitleOpacity(double t) => TarotCinematicMotion.curve(
    Curves.easeOutCubic,
    _seg(t, flipEnd + 0.16, revealEnd + 0.04),
  );

  /// Continue after name and orientation have landed.
  static double buttonOpacity(double t) =>
      TarotCinematicMotion.curve(Curves.easeOutCubic, _seg(t, revealEnd, 0.92));

  static double buttonSlide(double t) =>
      TarotCinematicMotion.curve(Curves.easeOutCubic, _seg(t, revealEnd, 0.92));

  /// Legacy alias for screen enter darken.
  static double metaOpacity(double t) => nameOpacity(t);
}
