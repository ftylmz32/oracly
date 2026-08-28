/// EPIC-024 — Shared tokens for the hero artwork system.
library;

import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Visual identity per major feature surface.
enum HeroArtTheme {
  orb,
  tarot,
  dream,
  astrology,
  birthChart,
  ai,
  premium,
  profile,
}

/// Timing, sizing, and palette for hero illustrations.
abstract final class HeroArtTokens {
  HeroArtTokens._();

  static const Duration breathCycle = Duration(milliseconds: 7200);
  static const Duration highlightCycle = Duration(milliseconds: 9600);
  static const Duration orbitCycle = Duration(milliseconds: 14000);

  static const double floatAmplitude = 5.5;
  static const double glowPulseMin = 0.72;
  static const double glowPulseMax = 1.0;

  /// Target fraction of viewport height (35–50%).
  static const double viewportFractionDefault = 0.42;
  static const double viewportFractionCompact = 0.35;
  static const double viewportFractionLarge = 0.48;

  static const double maxHeroSize = 360;
  static const double minHeroSize = 160;

  static Color accentFor(HeroArtTheme theme) => switch (theme) {
        HeroArtTheme.orb => AppColors.goldLight,
        HeroArtTheme.tarot => AppColors.gold,
        HeroArtTheme.dream => AppColors.secondaryPurple,
        HeroArtTheme.astrology => AppColors.goldLight,
        HeroArtTheme.birthChart => AppColors.gold,
        HeroArtTheme.ai => AppColors.primaryPurple,
        HeroArtTheme.premium => AppColors.goldLight,
        HeroArtTheme.profile => AppColors.gold,
      };

  static Color glowFor(HeroArtTheme theme) => switch (theme) {
        HeroArtTheme.orb => AppColors.glowGold,
        HeroArtTheme.tarot => AppColors.glowPurple,
        HeroArtTheme.dream => AppColors.glowPurple,
        HeroArtTheme.astrology => AppColors.glowGold,
        HeroArtTheme.birthChart => AppColors.glowGold,
        HeroArtTheme.ai => AppColors.glowPurple,
        HeroArtTheme.premium => AppColors.glowGold,
        HeroArtTheme.profile => AppColors.glowPurple,
      };

  static List<Color> backgroundGradient(HeroArtTheme theme) => switch (theme) {
        HeroArtTheme.orb => [
            AppColors.background,
            AppColors.surface,
            AppColors.backgroundSecondary,
          ],
        HeroArtTheme.tarot => [
            const Color(0xFF0A0618),
            AppColors.surface,
            const Color(0xFF1E1238),
          ],
        HeroArtTheme.dream => [
            const Color(0xFF08061A),
            const Color(0xFF12102A),
            const Color(0xFF1A1638),
          ],
        HeroArtTheme.astrology => [
            const Color(0xFF050510),
            AppColors.backgroundSecondary,
            const Color(0xFF181030),
          ],
        HeroArtTheme.birthChart => [
            const Color(0xFF060612),
            AppColors.surface,
            const Color(0xFF141028),
          ],
        HeroArtTheme.ai => [
            AppColors.background,
            const Color(0xFF100E24),
            AppColors.surface,
          ],
        HeroArtTheme.premium => [
            const Color(0xFF0C0818),
            const Color(0xFF1A1228),
            const Color(0xFF221830),
          ],
        HeroArtTheme.profile => [
            AppColors.backgroundSecondary,
            AppColors.surface,
            const Color(0xFF181230),
          ],
      };
}
