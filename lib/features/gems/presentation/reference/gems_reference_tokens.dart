/// Layout tokens for Mücevherler.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';

abstract final class GemsReferenceTokens {
  GemsReferenceTokens._();

  static const double screenHorizontal = OraclyChrome.screenSide;
  static const double screenTop = OraclyChrome.screenTop;
  static const double headerHeight = OraclyChrome.headerHeight;

  static const double headerToHero = AppSpacing.s8;
  static const double heroToIntro = AppSpacing.s8;
  static const double sectionGap = AppSpacing.s12;
  static const double rowGap = AppSpacing.s8;
  static const double sectionLabelToContent = AppSpacing.s12;
  static const double iconWell = 36;

  static const BorderRadius heroRadius = OraclyChrome.heroRadius;
  static const BorderRadius cardRadius = OraclyChrome.cardRadius;
  static const BorderRadius chipRadius = OraclyChrome.pillRadius;

  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(16, 14, 16, 14);
  static const EdgeInsets rowPadding = EdgeInsets.fromLTRB(14, 12, 12, 12);
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(16, 14, 16, 14);

  static double heroArtSizeFor(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final tight = h < 700;
    return (h * 0.16).clamp(
      tight ? 96.0 : 112.0,
      tight ? 140.0 : 168.0,
    );
  }

  static double scrollBottomInset(BuildContext context) =>
      AppLayout.scrollBottomInset(context);
}
