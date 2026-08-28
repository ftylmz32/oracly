/// Reference-accurate layout tokens for the Premium screen.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';

abstract final class PremiumReferenceTokens {
  PremiumReferenceTokens._();

  static const double screenHorizontal = OraclyChrome.screenSide;
  static const double screenTop = OraclyChrome.screenTop;
  static const double headerHeight = OraclyChrome.headerHeight;

  static const double headerToHero = AppSpacing.s8;
  static const double heroToIntro = AppSpacing.s12;
  static const double heroToBenefits = AppSpacing.s16;
  static const double benefitsToPlans = AppSpacing.s16;
  static const double plansToCta = AppSpacing.s16;
  static const double ctaToLinks = AppSpacing.s12;
  static const double sectionLabelToContent = AppSpacing.s8;
  static const double benefitItemGap = AppSpacing.s4;
  static const double planItemGap = AppSpacing.s8;

  static const BorderRadius heroRadius = OraclyChrome.heroRadius;
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(16, 12, 16, 12);

  static const BorderRadius benefitRadius = OraclyChrome.cardRadius;
  static const EdgeInsets benefitPadding =
      EdgeInsets.fromLTRB(16, 14, 16, 14);
  static const double benefitIconWell = 22;

  static const BorderRadius planRadius = OraclyChrome.cardRadius;
  static const EdgeInsets planPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 14);
  static const double planCardHeight = 88;

  /// Deep black / plum chamber + champagne gold accents (Premium only).
  static const Color ink = Color(0xFF050308);
  static const Color plum = Color(0xFF1C0E18);
  static const Color plumLift = Color(0xFF2A1522);
  static const Color champagne = Color(0xFFDCC9A3);
  static const Color champagneSoft = Color(0xFFE8D9B8);

  static const BorderRadius ctaRadius = OraclyChrome.pillRadius;
  static const EdgeInsets ctaPadding = AppLayout.referencePrimaryButtonPadding;

  static double heroArtSizeFor(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final tight = h < 700;
    return (h * 0.26).clamp(
      tight ? 148.0 : 176.0,
      tight ? 200.0 : 236.0,
    );
  }
}
