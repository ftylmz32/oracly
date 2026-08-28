/// EPIC-013 — Performance tiers for the living crystal orb.
library;

import 'package:flutter/material.dart';

import '../../../../features/premium/models/personalization_models.dart';
import '../../../../core/performance/oracly_performance_gate.dart';

enum OrbPerformanceTier {
  high,
  medium,
  low,
}

abstract final class OrbPerformance {
  OrbPerformance._();

  /// Chooses particle / effect density — device cap × user preference.
  static OrbPerformanceTier tierFor(BuildContext context) {
    return resolve(
      context: context,
      intensity: OraclyPerformanceGate.particleIntensity,
    );
  }

  static OrbPerformanceTier resolve({
    required BuildContext context,
    ParticleIntensity intensity = ParticleIntensity.medium,
  }) {
    final device = _deviceTier(context);
    final user = switch (intensity) {
      ParticleIntensity.low => OrbPerformanceTier.low,
      ParticleIntensity.medium => OrbPerformanceTier.medium,
      ParticleIntensity.high => OrbPerformanceTier.high,
    };
    return _lowerTier(device, user);
  }

  static OrbPerformanceTier _deviceTier(BuildContext context) {
    final media = MediaQuery.of(context);
    final dpr = media.devicePixelRatio;
    final shortSide = media.size.shortestSide;

    if (dpr <= 2.0 || shortSide < 360) return OrbPerformanceTier.low;
    if (dpr <= 2.75 || shortSide < 400) return OrbPerformanceTier.medium;
    return OrbPerformanceTier.high;
  }

  static OrbPerformanceTier _lowerTier(
    OrbPerformanceTier a,
    OrbPerformanceTier b,
  ) {
    const rank = {
      OrbPerformanceTier.low: 0,
      OrbPerformanceTier.medium: 1,
      OrbPerformanceTier.high: 2,
    };
    return rank[a]! <= rank[b]! ? a : b;
  }

  static int particleSeedCount(OrbPerformanceTier tier) => switch (tier) {
        OrbPerformanceTier.high => 21,
        OrbPerformanceTier.medium => 12,
        OrbPerformanceTier.low => 7,
      };

  static int dustSeedCount(OrbPerformanceTier tier) => switch (tier) {
        OrbPerformanceTier.high => 11,
        OrbPerformanceTier.medium => 6,
        OrbPerformanceTier.low => 3,
      };

  static int orbitParticleCount(OrbPerformanceTier tier) => switch (tier) {
        OrbPerformanceTier.high => 10,
        OrbPerformanceTier.medium => 6,
        OrbPerformanceTier.low => 4,
      };

  static bool enableShimmer(OrbPerformanceTier tier) =>
      tier != OrbPerformanceTier.low;

  static bool enableExternalOrbit(OrbPerformanceTier tier) => true;
}
