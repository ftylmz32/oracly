/// Reference-accurate layout tokens for the Astrology screen.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';

abstract final class AstrologyReferenceTokens {
  AstrologyReferenceTokens._();

  static const double screenHorizontal = OraclyChrome.screenSide;
  static const double screenTop = OraclyChrome.screenTop;
  static const double headerHeight = OraclyChrome.headerHeight;

  static const double headerToTabs = AppSpacing.s12;
  static const double leadToStrip = AppSpacing.s8;
  static const double tabsToSignCard = AppSpacing.s8;
  static const double signCardToStats = AppSpacing.s4;
  static const double statsToDaily = AppSpacing.s8;
  static const double dailyToCta = AppSpacing.s8;
  static const double dailyTitleToBody = AppSpacing.s8;

  static const double tabCircle = 30;
  static const double tabCircleSelected = 40;
  static const double tabGap = AppSpacing.s8;
  static const double tabLabelGap = 4;
  static const double tabRowHeight = 62;
  static const BorderRadius tabChipRadius =
      BorderRadius.all(Radius.circular(999));

  static const double signCardHeight = 208;
  static const double detailSignCardHeight = 160;
  static const double signCardHeightMax = 360;
  static const BorderRadius signCardRadius = OraclyChrome.heroRadius;
  static const EdgeInsets signCardPadding =
      EdgeInsets.fromLTRB(14, 10, 14, 10);
  static const double signIllustrationSize = 280;

  static double signCardHeightFor(double? viewportHeight) {
    return layoutFor(viewportHeight).heroHeight;
  }

  /// Hero absorbs leftover so CTA sits above nav without a dead lower band.
  static AstrologyViewportLayout layoutFor(double? viewportHeight) {
    final h = (viewportHeight == null || !viewportHeight.isFinite)
        ? 560.0
        : viewportHeight;
    final tight = h < 520;
    final gap = tight ? AppSpacing.s8 : AppSpacing.s12;
    const chrome = 48 + 52;
    final rem = (h - chrome - gap * 3).clamp(196.0, h);
    final heroMin = tight ? 228.0 : 256.0;
    final heroMax = tight
        ? 280.0
        : (h * 0.48).clamp(256.0, 340.0);
    return AstrologyViewportLayout(
      gap: gap,
      heroHeight: rem.clamp(heroMin, heroMax),
    );
  }

  static const double statBoxHeight = 68;
  static const BorderRadius statBoxRadius = OraclyChrome.cardRadius;
  static const double statGap = AppSpacing.s8;

  static const BorderRadius dailyCardRadius = OraclyChrome.cardRadius;
  static const EdgeInsets dailyCardPadding =
      EdgeInsets.fromLTRB(16, 14, 16, 16);
  static const EdgeInsets dailyCardPaddingCompact =
      EdgeInsets.fromLTRB(14, 12, 14, 14);
  static const double dailyIconSize = 34;

  static const double ctaHeight = OraclyChrome.buttonHeight;
  static const BorderRadius ctaRadius = OraclyChrome.pillRadius;
  static const Color cream = OraclyChrome.cream;

  /// Force text presentation so Android does not swap in colored emoji.
  static String textSymbol(String symbol) => '$symbol\uFE0E';
}

final class AstrologyViewportLayout {
  const AstrologyViewportLayout({
    required this.gap,
    required this.heroHeight,
  });

  final double gap;
  final double heroHeight;
}
