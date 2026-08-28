/// EPIC-021 — Gradient presets for surfaces and backgrounds.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Canonical gradient registry.
abstract final class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.surfaceElevated,
      AppColors.surface,
      AppColors.backgroundSecondary,
    ],
    stops: [0, 0.55, 1],
  );

  static const LinearGradient royalPurple = LinearGradient(
    begin: Alignment(-0.4, -1),
    end: Alignment(0.6, 1.2),
    colors: [
      Color(0xFF3D2A8C),
      AppColors.primaryPurple,
      AppColors.backgroundSecondary,
    ],
    stops: [0, 0.42, 1],
  );

  static const LinearGradient night = LinearGradient(
    begin: Alignment(-0.2, -1),
    end: Alignment(0.3, 1.1),
    colors: [
      Color(0xFF0A0814),
      AppColors.background,
      Color(0xFF030208),
    ],
    stops: [0, 0.45, 1],
  );

  /// Canonical deep cosmic base — near-black with midnight navy undertone.
  static const LinearGradient cosmicDeep = LinearGradient(
    begin: Alignment(-0.12, -1),
    end: Alignment(0.18, 1.08),
    colors: [
      Color(0xFF08060F),
      Color(0xFF0B0A14),
      AppColors.background,
      Color(0xFF030208),
    ],
    stops: [0.0, 0.32, 0.68, 1.0],
  );

  /// Primary CTA / badge gold — champagne → deep (strong contrast on dark).
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF6DEA0),
      AppColors.goldLight,
      AppColors.gold,
      AppColors.goldDeep,
    ],
    stops: [0.0, 0.28, 0.68, 1.0],
  );

  /// Soft gold wash for icon wells and chips.
  static LinearGradient get goldSoft => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.goldLight.withValues(alpha: 0.28),
          AppColors.gold.withValues(alpha: 0.16),
          AppColors.goldDeep.withValues(alpha: 0.08),
        ],
      );

  /// Deep purple chamber wash.
  static const LinearGradient purpleDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.surfaceElevated,
      AppColors.primaryPurple,
      AppColors.purpleDark,
    ],
    stops: [0.0, 0.48, 1.0],
  );

  /// Soft purple glass fill for cards.
  static LinearGradient get purpleGlass => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surfaceElevated.withValues(alpha: 0.98),
          AppColors.purple.withValues(alpha: 0.28),
          AppColors.purpleDark.withValues(alpha: 0.62),
          AppColors.backgroundSecondary.withValues(alpha: 0.96),
        ],
        stops: const [0.0, 0.32, 0.68, 1.0],
      );

  static const RadialGradient orb = RadialGradient(
    center: Alignment(0, -0.2),
    radius: 1.1,
    colors: [
      Color(0x66F4D58D),
      Color(0x336E52FF),
      Colors.transparent,
    ],
    stops: [0, 0.45, 1],
  );

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1826),
      AppColors.backgroundSecondary,
      AppColors.background,
    ],
    stops: [0, 0.35, 1],
  );

  static const LinearGradient premium = LinearGradient(
    begin: Alignment(-0.6, -0.8),
    end: Alignment(0.8, 1),
    colors: [
      Color(0xFF1C1830),
      AppColors.surfaceElevated,
      AppColors.backgroundSecondary,
    ],
    stops: [0, 0.5, 1],
  );

  // Legacy aliases.
  static const LinearGradient background = night;
  static const LinearGradient matteCard = primary;
  static const LinearGradient matteSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surfaceElevated, AppColors.surface],
  );
  static const LinearGradient goldBorder = gold;
  static LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.surfaceElevated.withValues(alpha: 0.94),
      AppColors.surface.withValues(alpha: 0.90),
      AppColors.background.withValues(alpha: 0.96),
    ],
    stops: const [0.0, 0.48, 1.0],
  );
}
