/// OR-300 / EPIC-013 — Premium motion controllers for the hero orb.
library;

import 'dart:math' show pi, sin;

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

    internalEnergy = AnimationController(
      vsync: vsync,
      duration: OrbConstants.internalEnergyDuration,
    )..repeat();
    internalEnergy.value = phase % 1.0;

    orbit = AnimationController(
      vsync: vsync,
      duration: OrbConstants.orbitDuration,
    )..repeat();
    orbit.value = (phase * 0.37) % 1.0;

    shimmerCycle = AnimationController(
      vsync: vsync,
      duration: OrbConstants.shimmerCycleDuration,
    )..repeat();

    tapPulse = AnimationController(
      vsync: vsync,
      duration: OrbConstants.tapPulseDuration,
    );
  }

  late final AnimationController breathe;
  late final AnimationController float;
  late final AnimationController innerGlow;
  late final AnimationController ringClockwise;
  late final AnimationController ringCounterClockwise;
  late final AnimationController particleDrift;
  late final AnimationController internalEnergy;
  late final AnimationController orbit;
  late final AnimationController shimmerCycle;
  late final AnimationController tapPulse;

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

  /// Internal caustic / energy rotation in radians.
  double get internalEnergyAngle => internalEnergy.value * pi * 2;

  /// External orbit phase [0, 1).
  double get orbitPhase => orbit.value;

  /// Shimmer sweep progress [0, 1] during active window, otherwise -1.
  double get shimmerSweep {
    final cycle = shimmerCycle.value;
    if (cycle > OrbConstants.shimmerActiveFraction) return -1;
    final t = cycle / OrbConstants.shimmerActiveFraction;
    return OrbConstants.motionCurve.transform(t);
  }

  /// Gentle scale bump when the orb is tapped.
  double get tapScaleBoost {
    if (tapPulse.value <= 0) return 0;
    return sin(tapPulse.value * pi) * OrbConstants.tapScaleBoostMax;
  }

  /// Brief glow lift on tap.
  double get tapGlowBoost {
    if (tapPulse.value <= 0) return 0;
    return sin(tapPulse.value * pi) * OrbConstants.tapGlowBoostMax;
  }

  /// Transform-only motions — isolated listenable for the scene shell.
  Listenable get transformMotion =>
      Listenable.merge([breathe, float, tapPulse]);

  void pulseTap() {
    tapPulse.forward(from: 0);
  }

  void dispose() {
    breathe.dispose();
    float.dispose();
    innerGlow.dispose();
    ringClockwise.dispose();
    ringCounterClockwise.dispose();
    particleDrift.dispose();
    internalEnergy.dispose();
    orbit.dispose();
    shimmerCycle.dispose();
    tapPulse.dispose();
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
