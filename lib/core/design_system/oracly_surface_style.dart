/// Canonical premium surfaces — deep celestial glass + restrained gold.
///
/// Three luminance tiers (base / elevated / hero). Borders stay thin; glow is
/// soft celestial light — never neon purple wash.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

/// Shared surface recipes for glass cards, nav chrome, and panels.
abstract final class OraclySurfaceStyle {
  OraclySurfaceStyle._();

  /// A — Base surface: near-black navy, quiet violet velvet.
  static LinearGradient get glassFill => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surfaceElevated.withValues(alpha: 0.88),
          AppColors.surface.withValues(alpha: 0.94),
          AppColors.purpleDark.withValues(alpha: 0.22),
          AppColors.nearBlack.withValues(alpha: 0.98),
        ],
        stops: const [0.0, 0.38, 0.72, 1.0],
      );

  /// B — Elevated card: brighter glass, soft violet density.
  static LinearGradient get glassElevated => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surfaceElevated.withValues(alpha: 0.94),
          AppColors.crystalVeil.withValues(alpha: 0.55),
          AppColors.purpleDark.withValues(alpha: 0.30),
          AppColors.surface.withValues(alpha: 0.96),
        ],
        stops: const [0.0, 0.32, 0.68, 1.0],
      );

  /// C — Hero / focal: richer velvet + restrained gold wash.
  static LinearGradient get glassPremium => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surfaceElevated.withValues(alpha: 0.97),
          AppColors.gold.withValues(alpha: 0.07),
          AppColors.purpleDark.withValues(alpha: 0.38),
          AppColors.midnightNavy.withValues(alpha: 0.97),
        ],
        stops: const [0.0, 0.20, 0.58, 1.0],
      );

  /// Selected / active — highlight gold edge feel, not neon fill.
  static LinearGradient get glassSelected => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.goldLight.withValues(alpha: 0.12),
          AppColors.crystalVeil.withValues(alpha: 0.50),
          AppColors.purpleDark.withValues(alpha: 0.44),
          AppColors.surface.withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.28, 0.62, 1.0],
      );

  /// Illuminated zodiac / accent chips.
  static LinearGradient get glassIlluminated => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.purpleDark.withValues(alpha: 0.72),
          AppColors.purple.withValues(alpha: 0.28),
          AppColors.surface.withValues(alpha: 0.94),
        ],
        stops: const [0.0, 0.48, 1.0],
      );

  /// Floating bottom navigation — translucent midnight glass.
  static LinearGradient get navBarFill => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.surfaceElevated.withValues(alpha: 0.78),
          AppColors.backgroundSecondary.withValues(alpha: 0.92),
          AppColors.background.withValues(alpha: 0.96),
        ],
        stops: const [0.0, 0.55, 1.0],
      );

  /// Cream navigation — Light appearance.
  static LinearGradient get navBarFillLight => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.ivory.withValues(alpha: 0.96),
          AppColors.light.secondary.withValues(alpha: 0.98),
          AppColors.light.surface.withValues(alpha: 0.99),
        ],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient glassFillOf(Brightness b) =>
      b == Brightness.light ? glassFillLight : glassFill;

  static LinearGradient glassElevatedOf(Brightness b) =>
      b == Brightness.light ? glassElevatedLight : glassElevated;

  static LinearGradient glassPremiumOf(Brightness b) =>
      b == Brightness.light ? glassPremiumLight : glassPremium;

  static LinearGradient glassSelectedOf(Brightness b) =>
      b == Brightness.light ? glassSelectedLight : glassSelected;

  static LinearGradient navBarFillOf(Brightness b) =>
      b == Brightness.light ? navBarFillLight : navBarFill;

  static LinearGradient get glassFillLight => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.ivory.withValues(alpha: 0.97),
          AppColors.light.secondary.withValues(alpha: 0.94),
          AppColors.light.surface.withValues(alpha: 0.98),
        ],
        stops: const [0.0, 0.52, 1.0],
      );

  static LinearGradient get glassElevatedLight => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.ivory.withValues(alpha: 0.98),
          AppColors.light.gold.withValues(alpha: 0.06),
          AppColors.cream.withValues(alpha: 0.96),
        ],
        stops: const [0.0, 0.45, 1.0],
      );

  static LinearGradient get glassPremiumLight => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.ivory.withValues(alpha: 0.98),
          AppColors.light.gold.withValues(alpha: 0.08),
          AppColors.light.purple.withValues(alpha: 0.05),
          AppColors.light.secondary.withValues(alpha: 0.97),
        ],
        stops: const [0.0, 0.22, 0.62, 1.0],
      );

  static LinearGradient get glassSelectedLight => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.light.gold.withValues(alpha: 0.14),
          AppColors.light.surface.withValues(alpha: 0.96),
          AppColors.light.secondary.withValues(alpha: 0.98),
        ],
        stops: const [0.0, 0.48, 1.0],
      );

  static Color goldBorder({
    required bool selected,
    required bool premium,
    double glowStrength = 1.0,
    bool elevated = false,
  }) {
    if (selected) {
      return AppColors.goldLight.withValues(alpha: 0.58);
    }
    if (premium) {
      return AppColors.gold.withValues(
        alpha: (0.46 * glowStrength).clamp(0.32, 0.52),
      );
    }
    if (elevated) {
      return AppColors.goldDeep.withValues(
        alpha: (0.34 * glowStrength).clamp(0.24, 0.44),
      );
    }
    return AppColors.goldDeep.withValues(
      alpha: (0.26 * glowStrength).clamp(0.18, 0.36),
    );
  }

  static double borderWidth({
    required bool selected,
    required bool premium,
    bool elevated = false,
  }) {
    if (selected) return AppBorderWidth.gold;
    if (premium) return AppBorderWidth.thin;
    if (elevated) return AppBorderWidth.hairline;
    return AppBorderWidth.hairline;
  }
}
