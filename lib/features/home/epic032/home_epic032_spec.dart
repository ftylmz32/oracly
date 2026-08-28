/// EPIC-032 — Approved Home (Evren) screen measurements.
/// Reverse-engineered from the 393×852 reference frame.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';

/// Canonical layout spec — every EPIC-032 Home widget reads from here only.
abstract final class HomeEpic032Spec {
  HomeEpic032Spec._();

  static const double referenceWidth = 393;
  static const double referenceHeight = 852;

  // ── Screen chrome ────────────────────────────────────────────────────────

  static const double horizontalInset = AppSpacing.s24;
  static const double screenTop = AppSpacing.s16;
  static const double headerHeight = AppLayout.statusHeaderHeight;
  static const double headerSideSlot = AppLayout.headerSideMinWidth;
  static const double headerAction = AppLayout.headerActionSize;
  static const double headerIcon = AppLayout.headerIconSize;

  static const double headerToWelcome = AppSpacing.s8;
  static const double welcomeTitleSize = 26;
  static const double welcomeTitleSizeCompact = 24;
  static const double welcomeSubtitleSize = 14;
  static const double welcomeSubtitleSizeCompact = 13.5;
  static const double welcomeTitleToSubtitle = AppSpacing.s12;

  static const double sectionGap = AppSpacing.s20;
  static const double sectionGapCompact = AppSpacing.s16;
  static const double sectionLabelSize = 11;
  static const double sectionLabelTracking = 2.8;
  static const double sectionLabelToContent = AppSpacing.s8;

  // ── Hero (horizontal — text left, moon right) ────────────────────────────

  static const double heroWidthFactor = 1.0;
  static const BorderRadius heroRadius = AppRadius.s28;
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(20, 20, 12, 20);
  static const int heroContentFlex = 54;
  static const int heroMoonFlex = 46;
  static const double heroMinHeight = 196;
  static const double heroMinHeightCompact = 172;
  static const double heroIllustrationMaxHeight = 168;
  static const double heroIllustrationMaxHeightCompact = 144;
  static const double heroIllustrationWidth = 148;
  static const double heroIllustrationWidthCompact = 124;
  static const double heroLabelToPercent = AppSpacing.s8;
  static const double heroPercentToAlignment = AppSpacing.s8;
  static const double heroAlignmentToBody = AppSpacing.s8;
  static const double heroBodyToButton = AppSpacing.s12;
  static const double heroButtonMinWidth = 148;
  static const double heroPercentSize = 44;

  // ── Feature grid 2×3 ─────────────────────────────────────────────────────

  static const double gridGap = AppSpacing.s12;
  static const double tileMinHeight = 104;
  static const double tileMinHeightCompact = 96;
  static const BorderRadius tileRadius = AppRadius.s24;
  static const EdgeInsets tilePadding = EdgeInsets.fromLTRB(18, 12, 18, 16);
  static const double tileIconWell = 48;
  static const double tileIcon = 26;
  static const double tileTitleSize = 12;
  static const double tileIconLift = -6;

  // ── Premium banner ───────────────────────────────────────────────────────

  static const BorderRadius premiumRadius = AppRadius.s24;
  static const EdgeInsets premiumPadding =
      EdgeInsets.fromLTRB(16, 12, 16, 12);
  static const double premiumMinHeight = 92;
  static const double premiumCrown = 68;

  // ── Reflection (YANSIT) ──────────────────────────────────────────────────

  static const BorderRadius reflectionRadius = AppRadius.s20;
  static const EdgeInsets reflectionPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const double reflectionMinHeight = 62;
  static const double reflectionIconWell = 40;
  static const double reflectionIcon = 22;

  // ── Discover (KEŞFET) trio ─────────────────────────────────────────────────

  static const BorderRadius exploreRadius = AppRadius.s20;
  static const EdgeInsets explorePadding =
      EdgeInsets.fromLTRB(16, 14, 16, 12);
  static const double exploreMinHeight = 96;
  static const double exploreGap = AppSpacing.s8;
  static const double exploreIcon = 22;

  // ── Daily energy strip ───────────────────────────────────────────────────

  static const BorderRadius dailyRadius = AppRadius.s20;
  static const EdgeInsets dailyPadding = EdgeInsets.fromLTRB(16, 12, 0, 12);
  static const double dailyMoonMaxHeight = 92;
  static const double dailyTitleToBody = AppSpacing.s8;
  static const double dailyBodyToChips = AppSpacing.s8;
  static const int dailyTextFlex = 6;
  static const int dailyArtFlex = 4;

  // ── Background effects ───────────────────────────────────────────────────

  static const double nebulaBlur = 72;
  static const double starGlowBlur = 18;
  static const double cardShadowBlur = 24;
  static const double cardGlowBlur = 14;

  // ── Responsive helpers ───────────────────────────────────────────────────

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 380;

  static double blockGap(BuildContext context) =>
      isCompact(context) ? sectionGapCompact : sectionGap;

  static double contentWidth(BuildContext context) =>
      AppLayout.contentWidth(context);

  static double heroWidth(BuildContext context) =>
      contentWidth(context) * heroWidthFactor;

  static double heroHeight(BuildContext context) =>
      isCompact(context) ? heroMinHeightCompact : heroMinHeight;

  static double heroIllustrationHeight(BuildContext context) =>
      isCompact(context)
          ? heroIllustrationMaxHeightCompact
          : heroIllustrationMaxHeight;

  static double heroIllustrationW(BuildContext context) =>
      isCompact(context) ? heroIllustrationWidthCompact : heroIllustrationWidth;

  static double tileHeight(BuildContext context) =>
      isCompact(context) ? tileMinHeightCompact : tileMinHeight;
}
