/// OR-300 — Premium motion controllers for the hero orb.
library;

import 'package:flutter/material.dart';

import '../../theme/home_presence.dart';
import 'orb_constants.dart';

/// Bundled [AnimationController]s — one per motion channel for efficient repaints.
class OrbAnimationBundle {
  OrbAnimationBundle({
    required TickerProvider vsync,
    double? syncPhase,
  }) {
    final phase = syncPhase ?? HomePresenceRhythm.clockPhase();

    breathe = AnimationController(
      vsync: vsync,
      duration: OrbConstants.breatheDuration,
    )..repeat(reverse: true);
    breathe.value = HomePresenceRhythm.breathe(phase);

    float = AnimationController(
      vsync: vsync,
      duration: OrbConstants.floatDuration,
    )..repeat(reverse: true);
    float.value = HomePresenceRhythm.float(phase);

    innerGlow = AnimationController(
      vsync: vsync,
      duration: OrbConstants.innerGlowDuration,
    )..repeat(reverse: true);
    innerGlow.value = HomePresenceRhythm.innerGlow(phase);

    ringClockwise = AnimationController(
      vsync: vsync,
      duration: OrbConstants.ringClockwiseDuration,
    )..repeat();
    ringClockwise.value = HomePresenceRhythm.ringClockwise(phase);

    ringCounterClockwise = AnimationController(
      vsync: vsync,
      duration: OrbConstants.ringCounterClockwiseDuration,
    )..repeat();
    ringCounterClockwise.value = HomePresenceRhythm.ringCounter(phase);

    particleDrift = AnimationController(
      vsync: vsync,
      duration: OrbConstants.particleDriftDuration,
    )..repeat();
    particleDrift.value = HomePresenceRhythm.particles(phase);
  }

  late final AnimationController breathe;
  late final AnimationController float;
  late final AnimationController innerGlow;
  late final AnimationController ringClockwise;
  late final AnimationController ringCounterClockwise;
  late final AnimationController particleDrift;

  /// Breathing scale 0.985 → 1.015.
  double get breatheScale {
    final t = OrbConstants.motionCurve.transform(breathe.value);
    return OrbConstants.breatheScaleMin +
        t * (OrbConstants.breatheScaleMax - OrbConstants.breatheScaleMin);
  }

  /// Vertical float ±3 px (6 px peak-to-peak), calm easeInOut.
  double get floatDy {
    final t = OrbConstants.motionCurve.transform(float.value);
    return (t * 2 - 1) * (OrbConstants.floatAmplitudePx / 2);
  }

  /// Inner glow opacity 0.85 ↔ 1.00.
  double get innerGlowOpacity {
    final t = OrbConstants.motionCurve.transform(innerGlow.value);
    return OrbConstants.innerGlowOpacityMin +
        t * (OrbConstants.innerGlowOpacityMax - OrbConstants.innerGlowOpacityMin);
  }

  /// Clockwise ring rotation [0, 1).
  double get ringClockwiseAngle => ringClockwise.value;

  /// Counter-clockwise ring rotation [0, 1).
  double get ringCounterClockwiseAngle => ringCounterClockwise.value;

  /// Slow particle drift phase [0, 1).
  double get particlePhase => particleDrift.value;

  /// Transform-only motions — isolated listenable for the scene shell.
  Listenable get transformMotion => Listenable.merge([breathe, float]);

  void dispose() {
    breathe.dispose();
    float.dispose();
    innerGlow.dispose();
    ringClockwise.dispose();
    ringCounterClockwise.dispose();
    particleDrift.dispose();
  }
}

/// Builds [OrbRenderContext] snapshots without triggering full-scene rebuilds.
extension OrbAnimationSnapshot on OrbAnimationBundle {
  /// Particle fade factor for a seed — smooth in/out, no hard cuts.
  double particleFade(OrbParticleSeed seed) {
    final fadePhase =
        (particlePhase * seed.fadeRate + seed.phase) % 1.0;
    final fadeT = OrbConstants.motionCurve.transform(fadePhase);
    return fadeT * (1 - fadeT) * 4;
  }
}
