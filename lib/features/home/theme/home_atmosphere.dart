/// OR-416 — Emotional atmosphere — color carries feeling before action.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/oracly_brand_signature.dart';
import 'home_focus.dart';

/// Purple = mystery · Gold = wisdom · Black = calm · Glass = purity.
abstract final class HomeAtmosphere {
  HomeAtmosphere._();

  // ── Emotional palette ────────────────────────────────────────────────────

  /// Mystery — deep violet nebula memory.
  static const Color mysteryViolet = OraclySignaturePalette.purpleMist;

  /// Wisdom — softened champagne gold, never harsh.
  static const Color wisdomGold = OraclySignaturePalette.wisdomGold;

  /// Calm — peaceful obsidian depth.
  static const Color calmObsidian = OraclySignaturePalette.calmObsidian;

  /// Purity — crystalline veil over glass.
  static const Color pureGlass = OraclySignaturePalette.pureGlass;

  /// Hopeful warmth — upper chamber, near the orb.
  static const Color hopefulWarm = OraclySignaturePalette.hopefulWarm;

  /// Cool mystery — lower discovery bands.
  static const Color coolMist = OraclySignaturePalette.coolMist;

  // ── Zone temperature [-1 cool … +1 warm] ─────────────────────────────────

  static double zoneTemperature(HomeFocusZone zone) => switch (zone) {
        HomeFocusZone.orb => 0.18,
        HomeFocusZone.spread => 0.10,
        HomeFocusZone.daily => 0.14,
        HomeFocusZone.premium => 0.08,
        HomeFocusZone.ai => -0.05,
        HomeFocusZone.cosmic => -0.12,
        HomeFocusZone.header => -0.08,
        HomeFocusZone.none => 0.0,
      };

  /// Blend base toward warm or cool emotional temperature.
  static Color temper(Color base, HomeFocusZone zone, {double strength = 0.10}) {
    final t = zoneTemperature(zone);
    if (t > 0) {
      return Color.lerp(base, hopefulWarm, t * strength)!;
    }
    if (t < 0) {
      return Color.lerp(base, coolMist, -t * strength)!;
    }
    return base;
  }

  /// Hero orb anchors — secondary elements yield emotional presence.
  static double orbAnchorWeight(HomeFocusZone zone) => switch (zone) {
        HomeFocusZone.orb => 1.0,
        HomeFocusZone.spread => 0.90,
        HomeFocusZone.daily => 0.87,
        HomeFocusZone.premium => 0.85,
        HomeFocusZone.ai => 0.82,
        HomeFocusZone.cosmic => 0.78,
        HomeFocusZone.header => 0.80,
        HomeFocusZone.none => 1.0,
      };

  /// Softer contrast — peaceful darks, hopeful lights, no harsh edges.
  static List<double> softContrastMatrix(double emphasis) {
    final c = 0.88 + emphasis * 0.10;
    final t = (1 - c) * 128;
    return <double>[
      c, 0, 0, 0, t,
      0, c, 0, 0, t,
      0, 0, c, 0, t,
      0, 0, 0, 1, 0,
    ];
  }

  /// Hopeful light at the orb chamber — quiet anchor.
  static RadialGradient orbHopeLight(double phase) {
    final breathe = 0.96 + 0.04 * sin(phase * pi * 2);
    return RadialGradient(
      center: const Alignment(0, -0.28),
      radius: 0.68,
      colors: [
        wisdomGold.withValues(alpha: 0.068 * breathe),
        mysteryViolet.withValues(alpha: 0.095 * breathe),
        AppColors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    );
  }

  /// Cool calm settles toward the lower chamber.
  static LinearGradient get lowerChamberCalm => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.transparent,
          calmObsidian.withValues(alpha: 0.06),
          calmObsidian.withValues(alpha: 0.14),
        ],
        stops: const [0.5, 0.82, 1.0],
      );

  /// Micro crystal shimmer — nearly invisible purity.
  static double crystalShimmer(double phase) =>
      0.012 + 0.010 * sin((phase + 0.15) * pi * 2);

  /// Micro reflected highlight drift.
  static double microHighlight(double phase) =>
      0.5 + 0.5 * sin((phase * 0.5 + 0.3) * pi * 2);

  /// Particle emotional warmth [0, 1] — gold near orb, violet below.
  static double particleWarmth(double yNorm) =>
      (1.0 - yNorm.clamp(0.0, 1.0)) * 0.65 + 0.35;
}
