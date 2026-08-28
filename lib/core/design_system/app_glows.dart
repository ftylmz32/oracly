/// EPIC-021 — Reusable glow presets.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'oracly_art_direction.dart';

/// Glow intensity presets for cards, orbs, and CTAs.
abstract final class AppGlows {
  AppGlows._();

  static List<BoxShadow> small({double strength = 1.0}) => [
        BoxShadow(
          color: AppColors.glowGold.withValues(
            alpha: OraclyArtDirection.clampGoldGlow(0.10 * strength),
          ),
          blurRadius: 12,
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> medium({double strength = 1.0}) => [
        BoxShadow(
          color: AppColors.glowGold.withValues(
            alpha: OraclyArtDirection.clampGoldGlow(0.14 * strength),
          ),
          blurRadius: 18,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppColors.glowPurple.withValues(
            alpha: OraclyArtDirection.clampVioletGlow(0.10 * strength),
          ),
          blurRadius: 20,
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> large({double strength = 1.0}) => [
        BoxShadow(
          color: AppColors.glowGold.withValues(
            alpha: OraclyArtDirection.clampGoldGlow(0.18 * strength),
          ),
          blurRadius: 28,
          spreadRadius: -2,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: AppColors.glowPurple.withValues(
            alpha: OraclyArtDirection.clampVioletGlow(0.14 * strength),
          ),
          blurRadius: 32,
          spreadRadius: -6,
        ),
      ];

  static List<BoxShadow> hero({double strength = 1.0}) => [
        BoxShadow(
          color: AppColors.glowGold.withValues(
            alpha: OraclyArtDirection.clampGoldGlow(0.20 * strength),
          ),
          blurRadius: 36,
        ),
        BoxShadow(
          color: AppColors.glowPurple.withValues(
            alpha: OraclyArtDirection.clampVioletGlow(0.14 * strength),
          ),
          blurRadius: 44,
          spreadRadius: -6,
        ),
      ];
}
