/// OR-999 — Hero Orb tokens (Home v1.0 FROZEN).
library;

import 'package:flutter/material.dart';

/// Layout derived from the 4096×4096 reference asset proportions.
abstract final class OrbConstants {
  OrbConstants._();

  // ── Canvas ────────────────────────────────────────────────────────
  static const double renderScale = 1.55;
  static const double referenceCanvasSize = 4096;

  // ── Motion curves (calm, no bounce) ───────────────────────────────
  static const Curve motionCurve = Curves.easeInOut;

  // ── 1. Breathing — harmonized to HomePresenceRhythm.masterCycle (12s) ──
  static const Duration breatheDuration = Duration(seconds: 12);
  static const double breatheScaleMin = 0.989;
  static const double breatheScaleMax = 1.011;

  // ── 2. Floating — same period, phase-offset at sync ─────────────────
  static const Duration floatDuration = Duration(seconds: 12);
  static const double floatAmplitudePx = 4.0;

  // ── 3. Golden rings — 4× and 5× master cycle ────────────────────────
  static const Duration ringClockwiseDuration = Duration(seconds: 48);
  static const Duration ringCounterClockwiseDuration = Duration(seconds: 60);

  // ── 4. Inner glow — 2× master frequency, calmer swing ─────────────
  static const Duration innerGlowDuration = Duration(seconds: 6);
  static const double innerGlowOpacityMin = 0.92;
  static const double innerGlowOpacityMax = 0.98;

  // ── 5. Floating particles — 6× master cycle ───────────────────────
  static const Duration particleDriftDuration = Duration(seconds: 72);
  static const Duration particleFadeDuration = Duration(seconds: 9);

  // ── EPIC-013 Living crystal motion ───────────────────────────────
  static const Duration internalEnergyDuration = Duration(seconds: 84);
  static const Duration orbitDuration = Duration(seconds: 36);
  static const Duration shimmerCycleDuration = Duration(seconds: 10);
  static const double shimmerActiveFraction = 0.14;
  static const Duration tapPulseDuration = Duration(milliseconds: 520);
  static const double tapScaleBoostMax = 0.028;
  static const double tapGlowBoostMax = 0.18;
  static const double externalOrbitRadiusScale = 1.14;
  static const double externalOrbitWobble = 0.018;

  /// Normalized reference regions (0–1 of canvas width/height).
  static const Offset sphereCenterNorm = Offset(0.5, 0.385);
  static const double sphereRadiusNorm = 0.285;

  static const Offset pedestalGlowCenterNorm = Offset(0.5, 0.79);
  static const double pedestalGlowRadiusNorm = 0.34;

  static const Offset ringBandCenterNorm = Offset(0.5, 0.835);
  static const double ringBandRadiusXNorm = 0.30;
  static const double ringBandRadiusYNorm = 0.045;

  static const double ringOuterScale = 1.08;
  static const double ringInnerScale = 0.92;

  // ── OR-999 Final polish (design frozen) ──────────────────────────
  static const double shellThicknessNorm = 0.094;
  static const double shellInnerRadiusNorm = 0.780;
  static const double fresnelStartNorm = 0.75;
  static const double facetSofteningStrength = 0.99;
  static const double glassTransparencyBoost = 0.44;
  static const double centerClearRadiusNorm = 0.102;
  static const double internalFogStrength = 1.92;
  static const double volumetricMistStrength = 1.24;
  static const double opticalDepthStrength = 1.34;
  static const double specularHighlightStrength = 1.48;
  static const double goldenIlluminationStrength = 1.38;
  static const double logoMetallicStrength = 1.50;
  static const double globalBloomStrength = 1.30;
  static const double nebulaBlurFactor = 0.17;
  static const double dustVisibility = 0.46;

  static const Offset logoCenterNorm = sphereCenterNorm;
  static const double logoRadiusNorm = 0.068;

  static const Offset lightDirectionNorm = Offset(-0.34, -0.38);

  static const double pedestalTopNorm = 0.58;
  static const double pedestalBottomNorm = 0.93;

  static const double lightTrailSweepRadians = 0.52;
  static const double lightTrailBlurSigma = 8.2;

  static double renderSize(double layoutSize) => layoutSize * renderScale;

  static double sphereRadius(double layoutSize) =>
      renderSize(layoutSize) * sphereRadiusNorm;

  static Offset sphereCenter(double layoutSize) {
    final size = renderSize(layoutSize);
    return Offset(
      size * sphereCenterNorm.dx,
      size * sphereCenterNorm.dy,
    );
  }
}

/// Deterministic particle seed — pseudo-random spread, stable across frames.
@immutable
class OrbParticleSeed {
  const OrbParticleSeed({
    required this.u,
    required this.v,
    required this.size,
    required this.alpha,
    required this.phase,
    required this.orbit,
    required this.driftRate,
    required this.fadeRate,
  });

  final double u;
  final double v;
  final double size;
  final double alpha;
  final double phase;
  final double orbit;
  final double driftRate;
  final double fadeRate;
}

/// Fixed particle field with varied fade/drift rates for organic motion.
abstract final class OrbParticleField {
  OrbParticleField._();

  static const List<OrbParticleSeed> seeds = [
    OrbParticleSeed(u: -0.12, v: -0.08, size: 0.006, alpha: 0.55, phase: 0.0, orbit: 0.018, driftRate: 0.82, fadeRate: 1.05),
    OrbParticleSeed(u: 0.10, v: -0.14, size: 0.005, alpha: 0.48, phase: 0.7, orbit: 0.014, driftRate: 0.64, fadeRate: 0.92),
    OrbParticleSeed(u: 0.16, v: 0.04, size: 0.007, alpha: 0.62, phase: 1.4, orbit: 0.020, driftRate: 0.91, fadeRate: 1.18),
    OrbParticleSeed(u: -0.18, v: 0.10, size: 0.005, alpha: 0.44, phase: 2.1, orbit: 0.016, driftRate: 0.73, fadeRate: 0.88),
    OrbParticleSeed(u: 0.04, v: 0.16, size: 0.006, alpha: 0.50, phase: 2.8, orbit: 0.012, driftRate: 0.58, fadeRate: 1.02),
    OrbParticleSeed(u: -0.06, v: -0.18, size: 0.005, alpha: 0.46, phase: 3.5, orbit: 0.015, driftRate: 0.69, fadeRate: 0.95),
    OrbParticleSeed(u: 0.20, v: -0.02, size: 0.004, alpha: 0.40, phase: 4.2, orbit: 0.013, driftRate: 0.77, fadeRate: 1.12),
    OrbParticleSeed(u: -0.14, v: -0.16, size: 0.005, alpha: 0.52, phase: 4.9, orbit: 0.017, driftRate: 0.86, fadeRate: 0.90),
    OrbParticleSeed(u: 0.08, v: 0.12, size: 0.006, alpha: 0.58, phase: 5.6, orbit: 0.019, driftRate: 0.62, fadeRate: 1.08),
    OrbParticleSeed(u: -0.22, v: 0.02, size: 0.004, alpha: 0.38, phase: 0.3, orbit: 0.011, driftRate: 0.55, fadeRate: 0.84),
    OrbParticleSeed(u: 0.14, v: 0.18, size: 0.005, alpha: 0.42, phase: 1.0, orbit: 0.014, driftRate: 0.71, fadeRate: 1.15),
    OrbParticleSeed(u: -0.04, v: 0.08, size: 0.007, alpha: 0.60, phase: 1.7, orbit: 0.021, driftRate: 0.94, fadeRate: 0.97),
    OrbParticleSeed(u: 0.22, v: 0.10, size: 0.004, alpha: 0.36, phase: 2.4, orbit: 0.010, driftRate: 0.51, fadeRate: 1.22),
    OrbParticleSeed(u: -0.10, v: 0.20, size: 0.005, alpha: 0.45, phase: 3.1, orbit: 0.013, driftRate: 0.66, fadeRate: 0.86),
    OrbParticleSeed(u: 0.02, v: -0.10, size: 0.006, alpha: 0.54, phase: 3.8, orbit: 0.016, driftRate: 0.79, fadeRate: 1.04),
    OrbParticleSeed(u: -0.16, v: -0.04, size: 0.005, alpha: 0.47, phase: 4.5, orbit: 0.015, driftRate: 0.68, fadeRate: 0.93),
    OrbParticleSeed(u: 0.12, v: -0.20, size: 0.004, alpha: 0.41, phase: 5.2, orbit: 0.012, driftRate: 0.60, fadeRate: 1.10),
    OrbParticleSeed(u: -0.08, v: 0.14, size: 0.006, alpha: 0.53, phase: 5.9, orbit: 0.018, driftRate: 0.88, fadeRate: 0.98),
    OrbParticleSeed(u: 0.18, v: -0.12, size: 0.004, alpha: 0.39, phase: 1.3, orbit: 0.011, driftRate: 0.53, fadeRate: 1.06),
    OrbParticleSeed(u: -0.11, v: 0.06, size: 0.0035, alpha: 0.43, phase: 2.6, orbit: 0.009, driftRate: 0.48, fadeRate: 0.89),
    OrbParticleSeed(u: 0.05, v: 0.19, size: 0.004, alpha: 0.37, phase: 4.1, orbit: 0.010, driftRate: 0.56, fadeRate: 1.14),
  ];

  /// Tiny magical dust — smaller, slower, softer twinkle.
  static const List<OrbParticleSeed> dustSeeds = [
    OrbParticleSeed(u: -0.20, v: -0.10, size: 0.003, alpha: 0.50, phase: 0.4, orbit: 0.008, driftRate: 0.40, fadeRate: 0.85),
    OrbParticleSeed(u: 0.18, v: -0.06, size: 0.0025, alpha: 0.44, phase: 1.2, orbit: 0.007, driftRate: 0.35, fadeRate: 0.90),
    OrbParticleSeed(u: -0.05, v: 0.20, size: 0.003, alpha: 0.48, phase: 2.0, orbit: 0.009, driftRate: 0.42, fadeRate: 0.88),
    OrbParticleSeed(u: 0.22, v: 0.14, size: 0.0028, alpha: 0.46, phase: 2.8, orbit: 0.007, driftRate: 0.38, fadeRate: 0.92),
    OrbParticleSeed(u: -0.15, v: 0.18, size: 0.0026, alpha: 0.42, phase: 3.6, orbit: 0.006, driftRate: 0.33, fadeRate: 0.86),
    OrbParticleSeed(u: 0.06, v: -0.18, size: 0.003, alpha: 0.52, phase: 4.4, orbit: 0.008, driftRate: 0.44, fadeRate: 0.94),
    OrbParticleSeed(u: -0.24, v: 0.04, size: 0.0024, alpha: 0.40, phase: 5.2, orbit: 0.006, driftRate: 0.36, fadeRate: 0.84),
    OrbParticleSeed(u: 0.10, v: 0.22, size: 0.0027, alpha: 0.45, phase: 6.0, orbit: 0.007, driftRate: 0.39, fadeRate: 0.91),
    OrbParticleSeed(u: -0.08, v: -0.14, size: 0.0022, alpha: 0.38, phase: 0.8, orbit: 0.005, driftRate: 0.31, fadeRate: 0.87),
    OrbParticleSeed(u: 0.16, v: 0.08, size: 0.0023, alpha: 0.41, phase: 3.2, orbit: 0.006, driftRate: 0.34, fadeRate: 0.93),
    OrbParticleSeed(u: -0.18, v: -0.02, size: 0.0021, alpha: 0.36, phase: 5.5, orbit: 0.005, driftRate: 0.30, fadeRate: 0.82),
  ];
}
