/// EPIC-026 — Cinematic lighting tokens and presets.
library;

import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Screen mood presets — palette only, no layout changes.
enum CinematicLightingPreset {
  neutral,
  home,
  dream,
  celestial,
  tarot,
  premium,
  companion,
}

/// Canonical timing and opacity for the five-layer light model.
abstract final class CinematicLightingTokens {
  CinematicLightingTokens._();

  static const Duration breathCycle = Duration(milliseconds: 9600);
  static const Duration fogCycle = Duration(milliseconds: 14000);

  // Layer opacities (modulated by preset).
  static const double vignetteStrength = 0.42;
  static const double noiseStrength = 0.035;
  static const double fogStrength = 0.12;
  static const double starMaxAlpha = 0.28;
  static const double particleMaxAlpha = 0.08;
  static const double goldHighlightStrength = 0.14;
  static const double heroSpillRadius = 1.35;

  static Color nebulaPrimary(CinematicLightingPreset p) => switch (p) {
        CinematicLightingPreset.home => AppColors.primaryPurple,
        CinematicLightingPreset.dream => const Color(0xFF6B8FD4),
        CinematicLightingPreset.celestial => AppColors.secondaryPurple,
        CinematicLightingPreset.tarot => AppColors.purpleDark,
        CinematicLightingPreset.premium => AppColors.gold,
        CinematicLightingPreset.companion => AppColors.primaryPurple,
        _ => AppColors.primaryPurple,
      };

  static Color nebulaSecondary(CinematicLightingPreset p) => switch (p) {
        CinematicLightingPreset.home => AppColors.backgroundSecondary,
        CinematicLightingPreset.dream => AppColors.secondaryPurple,
        CinematicLightingPreset.celestial => AppColors.goldLight,
        CinematicLightingPreset.tarot => AppColors.gold,
        CinematicLightingPreset.premium => AppColors.goldLight,
        CinematicLightingPreset.companion => AppColors.secondaryPurple,
        _ => AppColors.primaryPurple,
      };

  static double nebulaIntensity(CinematicLightingPreset p) => switch (p) {
        CinematicLightingPreset.home => 0.24,
        CinematicLightingPreset.dream => 0.18,
        CinematicLightingPreset.celestial => 0.20,
        CinematicLightingPreset.tarot => 0.16,
        CinematicLightingPreset.premium => 0.14,
        CinematicLightingPreset.companion => 0.12,
        _ => 0.18,
      };

  static int starCount(CinematicLightingPreset p) => switch (p) {
        CinematicLightingPreset.home => 90,
        CinematicLightingPreset.celestial => 110,
        _ => 72,
      };

  static int particleCount(CinematicLightingPreset p) => switch (p) {
        CinematicLightingPreset.home => 40,
        CinematicLightingPreset.premium => 48,
        _ => 28,
      };
}

/// Hero accent colors for light spill per theme.
abstract final class HeroLightColors {
  HeroLightColors._();

  static const orb = AppColors.goldLight;
  static const tarot = AppColors.gold;
  static const dream = AppColors.secondaryPurple;
  static const astrology = AppColors.goldLight;
  static const birthChart = AppColors.gold;
  static const ai = AppColors.primaryPurple;
  static const premium = AppColors.goldLight;
  static const profile = AppColors.gold;
}
