/// Compact Kahve Falı layout tokens — same rhythm as Tarot / Dream.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';

abstract final class CoffeeReferenceTokens {
  CoffeeReferenceTokens._();

  static const double screenHorizontal = OraclyChrome.screenSide;
  static const double screenTop = OraclyChrome.screenTop;
  static const double headerHeight = OraclyChrome.headerHeight;
  static const double gap = AppSpacing.s8;
  static const double headerToLead = AppSpacing.s12;
  static const double leadToHero = AppSpacing.s8;

  static const double ctaHeight = OraclyChrome.buttonHeight;
  static const BorderRadius ctaRadius = OraclyChrome.pillRadius;
  static const BorderRadius heroRadius = OraclyChrome.heroRadius;
  static const BorderRadius cardRadius = OraclyChrome.cardRadius;

  /// Warm cream on midnight glass — reading body, not stark white.
  static const Color cream = OraclyChrome.cream;

  /// Cup well behind the real photo — same across capture / wait / result.
  static const Color cupWell = Color(0xFF12080C);

  /// Soft candle amber used for atmosphere, never neon.
  static const Color amberGlow = Color(0xFFC47A2A);

  /// Veil / vignette ink over grounds.
  static const Color veilInk = Color(0xFF080512);

  static List<BoxShadow> cupFrameShadows({bool hero = false}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: hero ? 0.52 : 0.40),
          blurRadius: hero ? 28 : 18,
          offset: Offset(0, hero ? 14 : 8),
          spreadRadius: hero ? -4 : -2,
        ),
        BoxShadow(
          color: OraclyChrome.gold.withValues(alpha: hero ? 0.10 : 0.08),
          blurRadius: hero ? 22 : 14,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: amberGlow.withValues(alpha: hero ? 0.08 : 0.06),
          blurRadius: hero ? 36 : 22,
          offset: Offset(hero ? -6 : -4, hero ? 8 : 6),
        ),
      ];

  static double artHeightFor(double maxContentHeight) {
    final tight = maxContentHeight < 540;
    return (maxContentHeight * 0.54).clamp(
      tight ? 220.0 : 280.0,
      tight ? 340.0 : 440.0,
    );
  }
}
