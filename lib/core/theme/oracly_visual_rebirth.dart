/// EPIC-020 — ORACLY Visual Rebirth design language.
///
/// Single source of truth for premium luxury tokens across every screen.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import '../design_system/app_layout.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'craftsmanship_rhythm.dart';

/// Feature atmosphere presets — one product, many moods.
enum OraclyAmbience {
  /// Home portal — crystal orb chamber.
  home,

  /// Tarot ritual — ceremonial depth.
  tarot,

  /// Dream analysis — moonlight and soft fog.
  dream,

  /// Astrology & birth chart — celestial observatory.
  celestial,

  /// AI companion — warm sacred room.
  companion,

  /// Premium & profile — gold chamber.
  premium,

  /// Settings, about, privacy — quiet luxury.
  neutral,
}

/// EPIC-020 visual rebirth tokens.
abstract final class OraclyVisualRebirth {
  OraclyVisualRebirth._();

  // ── Composition ───────────────────────────────────────────────────────────

  static const double maxContentWidth = AppLayout.maxContentWidth;
  static const double sectionBreath = AppLayout.sectionGap;
  static const double cardBreath = AppLayout.sectionGapMedium;

  // ── Glass surfaces ────────────────────────────────────────────────────────

  static const double glassBorderAlpha = 0.28;
  static const double glassGoldHighlightAlpha = 0.14;
  static const double glassFillTopAlpha = 0.94;
  static const double glassFillBottomAlpha = 0.82;

  // ── Glow (performance-safe — prefer single shadow) ────────────────────────

  static List<BoxShadow> luxuryGlow({double strength = 1.0}) => [
        BoxShadow(
          color: AppColors.goldGlow.withValues(alpha: 0.10 * strength),
          blurRadius: 20,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: AppColors.glowPurple.withValues(alpha: 0.08 * strength),
          blurRadius: 28,
          spreadRadius: -8,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> orbBloom({double strength = 1.0}) => [
        BoxShadow(
          color: AppColors.goldGlow.withValues(alpha: 0.18 * strength),
          blurRadius: 36,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: AppColors.glowPurple.withValues(alpha: 0.22 * strength),
          blurRadius: 48,
          spreadRadius: -6,
        ),
      ];

  // ── Typography hierarchy ──────────────────────────────────────────────────

  static TextStyle get screenTitle => AppTextStyles.headlineSmall.copyWith(
        color: AppColors.goldLight.withValues(alpha: 0.94),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      );

  static TextStyle get sectionLabel => AppTextStyles.labelMedium.copyWith(
        color: AppColors.textSecondary.withValues(alpha: 0.72),
        letterSpacing: AppFontSizes.letterWide / 2,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get heroWhisper => AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textSecondary.withValues(alpha: 0.82),
        height: 1.62,
        letterSpacing: 0.2,
      );

  // ── Motion ────────────────────────────────────────────────────────────────

  static const Duration breathe = Duration(milliseconds: 4800);
  static const Duration shimmer = Duration(milliseconds: 3200);
  static const Duration float = Duration(milliseconds: 5600);

  static Curve get ease => CraftsmanshipRhythm.curve;

  // ── Screen chrome ─────────────────────────────────────────────────────────

  static EdgeInsets get screenPadding => EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      );

  static BorderRadius get cardRadius => AppRadius.glass;
}
