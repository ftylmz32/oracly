/// OR-411 — Home screen composition tokens.
///
/// Single-artwork rhythm: orb focal point, spread discovery, quiet support bands.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'home_atmosphere.dart';

/// Visual weight bands for the home composition (~45% / ~25% / ~30%).
enum HomeVisualTier {
  /// Hero spread — second focal point after the orb.
  featured,

  /// Daily, premium, AI — intentional but subordinate.
  primary,

  /// Cosmic discovery row — whispers at the edge of the composition.
  whisper,
}

/// Which band of the mystic launcher a grid segment belongs to.
enum HomeCompositionBand {
  explore,
  reflect,
  understand,
}

/// Spacing, depth, and weight tokens — one composition, not stacked widgets.
abstract final class HomeComposition {
  HomeComposition._();

  // ── Focal scale ──────────────────────────────────────────────────────────

  /// Hero orb canvas — dominates ~45% of attention.
  static const double orbSize =
      AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xxl + AppSpacing.sm;

  /// Soft pedestal glow diameter behind the orb.
  static const double orbHaloScale = 1.42;

  // ── Vertical rhythm (eye travel) ─────────────────────────────────────────

  static const double screenTop = AppSpacing.xl + AppSpacing.md;
  static const double screenBottom = AppSpacing.xxl + AppSpacing.xl;

  /// Header yields — orb owns the upper chamber.
  static const double headerToOrb = AppSpacing.lg;

  /// Silence after the hero focal point.
  static const double orbToSpread = AppSpacing.xxl + AppSpacing.lg;

  /// Spread and daily are related but distinct purposes.
  static const double spreadToDaily = AppSpacing.xl + AppSpacing.md;

  static const double dailyToPremium = AppSpacing.xl;

  /// Premium closes the primary narrative; discovery follows after breath.
  static const double premiumToDiscovery = AppSpacing.xxl + AppSpacing.sm;

  static const double aiToCosmic = AppSpacing.lg + AppSpacing.sm;

  /// Section label to first element.
  static const double labelToContent = AppSpacing.lg;

  /// In-grid tile separation.
  static const double tileGap = AppSpacing.lg;

  // ── Depth (background → architecture → glass → interactive → orb) ─────

  static const double depthGlass = 0;
  static const double depthInteractive = -1.5;
  static const double depthFeatured = -2.5;

  static Offset depthOffset(double tier) => Offset(0, tier);

  // ── Visual weight ────────────────────────────────────────────────────────

  static double tierOpacity(HomeVisualTier tier) => switch (tier) {
        HomeVisualTier.featured => 1.0,
        HomeVisualTier.primary => 0.96,
        HomeVisualTier.whisper => 0.88,
      };

  static double tierBorderAlpha(HomeVisualTier tier) => switch (tier) {
        HomeVisualTier.featured => 0.44,
        HomeVisualTier.primary => 0.36,
        HomeVisualTier.whisper => 0.26,
      };

  static double tierGoldGlowAlpha(HomeVisualTier tier) => switch (tier) {
        HomeVisualTier.featured => 0.20,
        HomeVisualTier.primary => 0.15,
        HomeVisualTier.whisper => 0.08,
      };

  static double tierScale(HomeVisualTier tier) => switch (tier) {
        HomeVisualTier.featured => 1.0,
        HomeVisualTier.primary => 1.0,
        HomeVisualTier.whisper => 0.985,
      };

  // ── Background focal shaft (orb chamber) ─────────────────────────────────

  static RadialGradient orbChamberGlow(double phase) =>
      HomeAtmosphere.orbHopeLight(phase);

  static RadialGradient get orbPedestalGlow => RadialGradient(
        colors: [
          HomeAtmosphere.mysteryViolet.withValues(alpha: 0.12),
          HomeAtmosphere.wisdomGold.withValues(alpha: 0.045),
          AppColors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      );
}
