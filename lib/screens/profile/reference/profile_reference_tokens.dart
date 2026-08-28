/// Reference-accurate layout tokens for the Profile screen.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/oracly_chrome.dart';

abstract final class ProfileReferenceTokens {
  ProfileReferenceTokens._();

  static const double screenHorizontal = OraclyChrome.screenSide;
  static const double screenTop = OraclyChrome.screenTop;
  static const double headerHeight = OraclyChrome.headerHeight;

  static const double headerToHero = AppSpacing.s8;

  /// Tiered vertical rhythm — not one equal gap.
  static const double afterHero = AppSpacing.s20;
  static const double afterHighlight = AppSpacing.s16;
  static const double afterStory = AppSpacing.s16;
  static const double withinUtility = AppSpacing.s8;
  static const double beforePremium = AppSpacing.s24;
  static const double afterPremium = AppSpacing.s16;

  /// Legacy alias — prefer tiered gaps above.
  static const double heroToRows = AppSpacing.s12;
  static const double settingsItemGap = AppSpacing.s8;

  static const double avatarSize = 72;
  static const double avatarBorderWidth = 1.85;

  static const BorderRadius heroRadius = OraclyChrome.heroRadius;
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(16, 14, 16, 14);

  static const BorderRadius settingsRadius = OraclyChrome.cardRadius;
  static const EdgeInsets settingsPadding = EdgeInsets.fromLTRB(12, 10, 10, 10);
  static const double settingsIconWell = OraclyChrome.iconWell;

  static const BorderRadius membershipRadius = OraclyChrome.cardRadius;
  static const EdgeInsets membershipPadding = EdgeInsets.fromLTRB(12, 8, 12, 8);
  static const EdgeInsets statCardPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );
  static const double statCardHeight = 58;
  static const double statGap = AppSpacing.s8;
  static const BorderRadius statRadius = OraclyChrome.cardRadius;
  static const double achievementCardHeight = 52;
  static const BorderRadius achievementRadius = OraclyChrome.cardRadius;
  static const double sectionLabelToContent = AppSpacing.s4;
  static const double achievementItemGap = AppSpacing.s4;

  /// Alias — nav height + system safe area + comfortable margin.
  /// Never invent a smaller per-screen bottom pad.
  static double scrollBottomInset(BuildContext context) =>
      AppLayout.scrollBottomInset(context) + AppSpacing.s8;
}
