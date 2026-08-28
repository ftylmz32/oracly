/// OR-411 — Home screen composition tokens (EPIC-022 layout).
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import 'home_atmosphere.dart';

/// Visual weight bands for the home composition.
enum HomeVisualTier {
  featured,
  primary,
  whisper,
}

/// Which band of the mystic launcher a grid segment belongs to.
enum HomeCompositionBand {
  explore,
  reflect,
  understand,
}

/// Spacing, depth, and weight tokens — EPIC-022 six-section rhythm.
abstract final class HomeComposition {
  HomeComposition._();

  // ── EPIC-022 section chrome ──────────────────────────────────────────────

  static const double statusHeaderHeight = AppLayout.statusHeaderHeight;

  /// Hero card occupies ~38–42% of first viewport.
  static const double heroViewportFraction = AppLayout.heroViewportFraction;

  static const double quickActionCardHeight = AppLayout.quickActionCardHeight;

  static const double exploreRowHeight = AppLayout.exploreRowHeight;

  static const double exploreCardWidth = AppLayout.exploreCardWidth;

  static const double exploreCardWidthWide = AppLayout.exploreCardWidthWide;

  // ── Focal scale ──────────────────────────────────────────────────────────

  /// Hero orb canvas — +18% over EPIC-018 baseline (176 → ~208).
  static const double _orbSizeBaseline =
      AppSpacing.s48 + AppSpacing.s48 + AppSpacing.s48 + AppSpacing.s32 + AppSpacing.s24;

  static const double orbSize = _orbSizeBaseline * 1.18;

  static const double orbHaloScale = 1.52;

  static const double orbContainerOverlap = 18;

  // ── Vertical rhythm ──────────────────────────────────────────────────────

  static const double screenTop = AppLayout.screenTop;

  static const double screenBottom = AppLayout.screenBottom;

  static const double headerToGreeting = AppSpacing.s8;

  static const double greetingToHero = AppLayout.sectionGapMedium;

  static const double heroToQuickActions = AppLayout.sectionGap;

  static const double quickActionsToPremium = AppLayout.sectionGap;

  static const double premiumToReflection = AppLayout.sectionGap;

  static const double reflectionToDiscover = AppLayout.sectionGapMedium;

  static const double discoverToDaily = AppLayout.sectionGap;

  // Legacy aliases
  static const double quickActionsToDaily = quickActionsToPremium;
  static const double dailyToPremium = premiumToReflection;
  static const double premiumToExplore = premiumToReflection;
  static const double exploreBandGap = reflectionToDiscover;

  // Legacy aliases
  static const double headerToOrb = greetingToHero;
  static const double orbToSpread = heroToQuickActions;
  static const double whisperToSpread = heroToQuickActions;
  static const double spreadToDaily = discoverToDaily;
  static const double premiumToDiscovery = premiumToReflection;
  static const double aiToCosmic = reflectionToDiscover;

  static const double labelToContent = AppLayout.labelToContent;

  static const double tileGap = AppLayout.gridGap;

  // ── Depth ────────────────────────────────────────────────────────────────

  static const double depthGlass = 0;
  static const double depthInteractive = -1.5;
  static const double depthFeatured = -2.5;

  static Offset depthOffset(double tier) => Offset(0, tier);

  static double heroCardHeight(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).height;
    final safeTop = MediaQuery.paddingOf(context).top;
    final firstFold = viewport - safeTop - statusHeaderHeight;
    return (firstFold * heroViewportFraction).clamp(280.0, 420.0);
  }

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

  static RadialGradient orbChamberGlow(double phase) =>
      HomeAtmosphere.orbHopeLight(phase);

  static RadialGradient get orbPedestalGlow => RadialGradient(
        colors: [
          HomeAtmosphere.mysteryViolet.withValues(alpha: 0.16),
          HomeAtmosphere.wisdomGold.withValues(alpha: 0.06),
          AppColors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      );
}
