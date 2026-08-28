/// EPIC-023 — Premium card sizing, glow, and layout tokens.
library;

import 'package:flutter/material.dart';

import '../app_radius.dart';
import '../app_spacing.dart';

/// Outer glow intensity presets.
enum PremiumCardGlow {
  none,
  small,
  medium,
  large,
  hero,
}

/// Visual tier for card emphasis.
enum PremiumCardTier {
  whisper,
  standard,
  featured,
  hero,
}

/// Shared constants — every premium card reads from here.
abstract final class PremiumCardTokens {
  PremiumCardTokens._();

  static const double pressScale = 0.98;
  static const Duration pressDuration = Duration(milliseconds: 180);
  static const Duration shimmerCycle = Duration(milliseconds: 4800);
  static const Duration gradientCycle = Duration(milliseconds: 12000);

  static const EdgeInsets paddingStandard = AppSpacing.card;
  static const EdgeInsets paddingCompact =
      EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12);
  static const EdgeInsets paddingHero =
      EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s24);

  static const BorderRadius radiusStandard = AppRadius.s24;
  static const BorderRadius radiusLarge = AppRadius.s28;
  static const BorderRadius radiusHero = AppRadius.s32;

  /// Illustration occupies ~35–45% of card width.
  static const int illustrationFlex = 4;
  static const int contentFlex = 6;

  static const double iconContainerSm = 44;
  static const double iconContainerMd = 52;
  static const double iconContainerLg = 64;

  static PremiumCardGlow glowForTier(PremiumCardTier tier) => switch (tier) {
        PremiumCardTier.whisper => PremiumCardGlow.small,
        PremiumCardTier.standard => PremiumCardGlow.medium,
        PremiumCardTier.featured => PremiumCardGlow.large,
        PremiumCardTier.hero => PremiumCardGlow.hero,
      };

  static BorderRadius radiusForTier(PremiumCardTier tier) => switch (tier) {
        PremiumCardTier.whisper => radiusStandard,
        PremiumCardTier.standard => radiusLarge,
        PremiumCardTier.featured => radiusLarge,
        PremiumCardTier.hero => radiusHero,
      };
}
