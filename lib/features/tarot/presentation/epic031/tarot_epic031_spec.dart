/// EPIC-031 — Approved Tarot main screen measurements (reference three-card).
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';

abstract final class TarotEpic031Spec {
  TarotEpic031Spec._();

  static const double referenceWidth = 393;
  static const double maxContentWidth = AppLayout.maxContentWidth;

  static const double horizontalInset = OraclyChrome.screenSide;
  static const double screenTop = AppSpacing.s4;

  static const double headerHeight = OraclyChrome.headerHeight;
  static const double headerAction = AppLayout.headerActionSize;
  static const double headerIcon = AppLayout.headerIconSize;

  static const double headerToTabs = AppSpacing.s4;
  static const double tabsToHero = AppSpacing.s4;
  static const double heroToTitle = AppSpacing.s4;
  static const double titleToSubtitlePrimary = AppSpacing.s4;
  static const double subtitlePrimaryToSecondary = AppSpacing.s4;
  static const double subtitleToButton = AppSpacing.s4;
  static const double buttonToHistory = AppSpacing.s4;

  static const double tabHeight = OraclyChrome.chipHeight;
  static const double tabGap = AppSpacing.s4;
  static const BorderRadius tabRadius = OraclyChrome.chipRadius;
  static const double tabFontSize = 11;
  static const double tabLetterSpacing = 0.2;

  // ── Three-card hero (reference) ────────────────────────────────────────

  static const double trioHeight = 228;
  static const double centerCardWidth = 128;
  static const double centerCardHeight = 198;
  static const double sideCardWidth = 98;
  static const double sideCardHeight = 152;
  static const double sideTiltRadians = 0.26;
  static const double sideOffsetX = 78;
  static const double sideOffsetY = 10;
  static const double cardRadius = 18;

  static const double primaryButtonHeight = OraclyChrome.buttonHeight;
  static const EdgeInsets primaryButtonPadding =
      EdgeInsets.symmetric(horizontal: 18, vertical: 12);
  static const BorderRadius primaryButtonRadius = OraclyChrome.pillRadius;

  static const double historyLabelSize = 13;
  static const double historyLabelTracking = 0.3;

  // Legacy aliases kept for unused history row widgets.
  static const double historyLabelToRows =
      AppLayout.referenceSectionLabelToContent;
  static const double historyRowGap = AppSpacing.s8;
  static const BorderRadius historyRowRadius = AppRadius.s24;
  static const EdgeInsets historyRowPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const double heroTitleSize = 32;
  static const double heroTitleTracking = 8;
  static const double subtitlePrimaryAlpha = 0.86;
  static const double subtitleSecondaryAlpha = 0.72;
  static const double heroBottomInset = AppSpacing.s4;
  static const int deckCardCount = 3;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 380;

  static double contentWidth(BuildContext context) =>
      AppLayout.contentWidth(context);

  /// Mid phones (~360–400) get a slightly larger trio for artwork focus.
  static double trioScale(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 0.92;
    if (w < 400) return 1.0;
    return 1.04;
  }

  /// Hero height for the entry deck; question + spreads scroll below.
  static TarotViewportLayout layoutFor(double maxHeight) {
    final tight = maxHeight < 540;
    final gap = tight ? 4.0 : 6.0;
    final hero = tight ? 176.0 : 208.0;
    return TarotViewportLayout(gap: gap, heroHeight: hero);
  }
}

final class TarotViewportLayout {
  const TarotViewportLayout({
    required this.gap,
    required this.heroHeight,
  });

  final double gap;
  final double heroHeight;
}

enum TarotEpic031Category {
  daily('Günlük Fal', 'daily'),
  love('Aşk', 'love'),
  career('Kariyer', 'career'),
  general('Genel', 'general');

  const TarotEpic031Category(this.label, this.topicId);

  final String label;
  final String topicId;
}
