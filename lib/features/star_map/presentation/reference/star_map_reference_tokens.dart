/// Reference-accurate layout tokens for the Yıldızname screen.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';

abstract final class StarMapReferenceTokens {
  StarMapReferenceTokens._();

  static const double screenHorizontal = OraclyChrome.screenSide;
  static const double screenTop = OraclyChrome.screenTop;
  static const double headerHeight = OraclyChrome.headerHeight;

  static const double headerToChart = AppSpacing.s12;
  static const double leadToHero = AppSpacing.s8;
  static const double chartToIntro = AppSpacing.s8;
  static const double introToMenus = AppSpacing.s8;
  static const double chartToMenus = AppSpacing.s8;
  static const double chartToStatus = AppSpacing.s12;
  static const double statusToMenus = AppSpacing.s8;
  static const double statusBlockHeight = 100;
  static const double introCardHeight = 84;
  static const BorderRadius introCardRadius = OraclyChrome.cardRadius;
  static const EdgeInsets introCardPadding =
      EdgeInsets.fromLTRB(14, 8, 14, 8);

  static const double chartWidthFactor = 0.86;
  static const double chartMaxDiameter = 312;
  static const double chartMinDiameter = 220;
  static const BorderRadius chartRadius = OraclyChrome.heroRadius;

  static const double menuCardHeight = 56;
  static const double menuCardGap = AppSpacing.s4;
  static const BorderRadius menuCardRadius = OraclyChrome.cardRadius;
  static const EdgeInsets menuCardPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 6);

  static const double ctaHeight = OraclyChrome.buttonHeight;
  static const BorderRadius ctaRadius = OraclyChrome.pillRadius;
  static const Color cream = OraclyChrome.cream;

  /// Archive chamber DNA — stone ink, violet sky, candle brass.
  static const Color archiveInk = Color(0xFF07040F);
  static const Color violetSky = Color(0xFF1A0A2E);
  static const Color candleAmber = Color(0xFFC4A574);
  static const Color brassGlow = Color(0xFFD4A86A);

  static double chartDiameter(BuildContext context, double contentWidth) {
    final target = contentWidth * chartWidthFactor;
    return target.clamp(chartMinDiameter, chartMaxDiameter);
  }

  /// Hero fills leftover; chapters continue the story below.
  static double chartDiameterFor({
    required double maxHeight,
    required double contentWidth,
  }) {
    final tight = maxHeight < 540;
    final byWidth = contentWidth * chartWidthFactor;
    const stackBelow = 420.0;
    final byHeight = (maxHeight - stackBelow).clamp(
      chartMinDiameter,
      chartMaxDiameter,
    );
    final target = byWidth < byHeight ? byWidth : byHeight;
    if (tight) return target.clamp(chartMinDiameter, 280.0);
    if (maxHeight < 620) return target.clamp(chartMinDiameter, 328.0);
    return target.clamp(chartMinDiameter, chartMaxDiameter);
  }

  static double scrollBottom(BuildContext context) =>
      AppLayout.scrollBottomInset(context);
}
