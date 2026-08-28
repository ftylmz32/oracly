/// Premium surface depth — shadow, gold edge, velvet rim.
///
/// Consumed by [OraclyGlassCard] and surface chrome. Screens do not invent
/// Material Card shadows.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'oracly_art_direction.dart';
import 'oracly_surface_style.dart';

/// Depth + gold-edge recipes for celestial glass / velvet cards.
abstract final class OraclySurfaceDepth {
  OraclySurfaceDepth._();

  static const BorderRadius radius = AppRadius.s20;
  static const BorderRadius radiusHero = AppRadius.s24;
  static const BorderRadius radiusChamber = AppRadius.s28;

  /// Soft contact + violet veil + antique gold kiss.
  static List<BoxShadow> cardShadows({
    required bool premium,
    required bool selected,
    required bool elevated,
    required bool isLight,
    double glowStrength = 1.0,
  }) {
    final gold = OraclyArtDirection.clampGoldGlow(
      selected
          ? 0.18
          : premium
              ? 0.11 * glowStrength
              : elevated
                  ? 0.07 * glowStrength
                  : 0.05 * glowStrength,
    );
    final violet = OraclyArtDirection.clampVioletGlow(
      selected
          ? 0.12
          : premium
              ? 0.09 * glowStrength
              : 0.05 * glowStrength,
    );
    final contact = isLight
        ? (premium ? 0.12 : elevated ? 0.08 : 0.06)
        : (premium ? 0.48 : elevated ? 0.40 : 0.36);

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: contact),
        blurRadius: premium || selected ? 22 : elevated ? 16 : 14,
        offset: Offset(0, premium || selected ? 9 : elevated ? 7 : 6),
        spreadRadius: -2,
      ),
      BoxShadow(
        color: AppColors.nearBlack.withValues(
          alpha: isLight ? 0.04 : (premium ? 0.28 : 0.18),
        ),
        blurRadius: premium ? 28 : 18,
        offset: const Offset(0, 14),
        spreadRadius: -8,
      ),
      BoxShadow(
        color: AppColors.glowPurple.withValues(
          alpha: isLight ? violet * 0.4 : violet,
        ),
        blurRadius: premium || selected ? 20 : 14,
        spreadRadius: -5,
      ),
      BoxShadow(
        color: AppColors.glowGold.withValues(alpha: gold),
        blurRadius: selected ? 18 : premium ? 14 : 10,
        spreadRadius: -3,
      ),
    ];
  }

  /// Outer antique-gold rim color (selected / premium / elevated / base).
  static Color goldEdge({
    required bool selected,
    required bool premium,
    bool elevated = false,
    double glowStrength = 1.0,
  }) =>
      OraclySurfaceStyle.goldBorder(
        selected: selected,
        premium: premium,
        elevated: elevated,
        glowStrength: glowStrength,
      );

  static double goldEdgeWidth({
    required bool selected,
    required bool premium,
    bool elevated = false,
  }) =>
      OraclySurfaceStyle.borderWidth(
        selected: selected,
        premium: premium,
        elevated: elevated,
      );

  /// Soft inner highlight — velvet lip inside the gold edge.
  static Color innerVelvetRim({
    required bool premium,
    required bool selected,
  }) {
    if (selected) {
      return AppColors.goldLight.withValues(alpha: 0.22);
    }
    if (premium) {
      return AppColors.ivory.withValues(alpha: 0.10);
    }
    return AppColors.ivory.withValues(alpha: 0.06);
  }
}
