/// Reference-accurate layout tokens for the Dream Analysis screen.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';

abstract final class DreamReferenceTokens {
  DreamReferenceTokens._();

  static const double screenHorizontal = OraclyChrome.screenSide;
  static const double screenTop = OraclyChrome.screenTop;
  static const double headerHeight = OraclyChrome.headerHeight;

  static const double headerToIntro = AppSpacing.s4;
  static const double introToIllustration = AppSpacing.s4;
  static const double headerToIllustration = AppSpacing.s8;
  static const double illustrationToActions = AppSpacing.s8;
  static const double actionsToRecent = AppSpacing.s8;
  static const double sectionLabelToList = AppSpacing.s4;
  static const double recentItemGap = AppSpacing.s8;

  static const BorderRadius illustrationRadius = OraclyChrome.heroRadius;
  static const double illustrationHeightFactor = 0.42;
  static const double illustrationMinHeight = 180;
  static const double illustrationMaxHeight = 280;
  static const EdgeInsets illustrationInnerPadding = EdgeInsets.all(2);

  static const double actionButtonHeight = OraclyChrome.buttonHeight;
  static const BorderRadius actionRadius = OraclyChrome.pillRadius;
  static const double actionGap = AppSpacing.s8;

  static const double recentCardHeight = 58;
  static const BorderRadius recentCardRadius = OraclyChrome.cardRadius;
  static const double recentThumbSize = 40;
  static const BorderRadius recentThumbRadius = BorderRadius.all(
    Radius.circular(10),
  );
  static const EdgeInsets recentCardPadding = EdgeInsets.fromLTRB(
    OraclyChrome.cardPadH,
    OraclyChrome.cardPadV,
    OraclyChrome.cardPadH,
    OraclyChrome.cardPadV,
  );

  static const double _introHeight = 20;
  static const double _sectionBlockHeight = 28;

  static double illustrationHeight(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).height;
    return (viewport * illustrationHeightFactor)
        .clamp(illustrationMinHeight, illustrationMaxHeight);
  }

  static double illustrationHeightFor(double maxContentHeight) {
    return layoutFor(maxContentHeight).heroHeight;
  }

  /// Hero fills leftover; actions + recents stay compact above nav.
  static DreamViewportLayout layoutFor(double maxHeight) {
    final tight = maxHeight < 540;
    final gap = tight ? 4.0 : 8.0;
    const recents =
        recentCardHeight * 2 + recentItemGap + _sectionBlockHeight;
    const chrome = headerHeight + _introHeight + actionButtonHeight + recents;
    final rem = (maxHeight - chrome - gap * 3).clamp(
      illustrationMinHeight,
      maxHeight,
    );
    final heroMin = tight ? 172.0 : illustrationMinHeight;
    final heroMax = tight
        ? 236.0
        : (maxHeight * illustrationHeightFactor).clamp(236.0, 340.0);
    return DreamViewportLayout(
      gap: gap,
      heroHeight: rem.clamp(heroMin, heroMax),
    );
  }
}

final class DreamViewportLayout {
  const DreamViewportLayout({
    required this.gap,
    required this.heroHeight,
  });

  final double gap;
  final double heroHeight;
}
