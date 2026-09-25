/// OR-1000 / OR-432 / Phase 7B — Tarot module design tokens.
///
/// Live table chrome reads chamber/physicality tokens here.
/// Prefer [AppColors] / [AppLayout] / [AppSpacing] when a global owns the value.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_layout.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/oracly_brand_signature.dart';

/// Layout and motion constants for the Tarot ritual flow.
abstract final class TarotTokens {
  TarotTokens._();

  static const double maxContentWidth = AppLayout.maxContentWidth;
  static const double ritualOrbSize = 148;
  static const double homeOrbSize = 208;
  static const double deckSelectionOrbSize = 176;

  /// Legacy selection/reveal card ratio (not the live ritual shell).
  static const double cardAspectRatio = 0.58;
  static const double cardCornerRadius = 12;

  /// Live ritual card physicality — table / deck / flight path.
  static const double ritualCardWidth = 132;
  static const double ritualCardHeight = 222;
  static const double ritualCardRadius = 18;
  static const double ritualCardAspectRatio =
      ritualCardWidth / ritualCardHeight;

  // ── Live table chamber (TarotTableBackground / overlays) ───────────────

  /// Table void — slightly lifted from [AppColors.nearBlack] for cloth depth.
  static const Color tableVoid = Color(0xFF05030A);
  static const Color tableNavyMid = Color(0xFF1A1230);
  static const Color tableNavyDeep = Color(0xFF0B0716);

  /// Candle warm spill — same hex as [AppColors.gold].
  static const Color tableCandleWarm = AppColors.gold;

  /// Deeper candle edge (warmer than [AppColors.goldDeep]).
  static const Color tableCandleDeep = Color(0xFFC48A3A);
  static const Color tableVioletBloom = Color(0xFF6B3FA0);
  static const Color tableChipPlate = Color(0xFF0C0916);
  static const Color tableChipSelected = Color(0xFF2A1847);
  static const Color tableReadingPlate = Color(0xFF0A0714);
  static const Color tableMiniCardFill = Color(0xFF1A1028);

  static const double tableTitleTopGap = 8;
  static const double tableHintBottomInset = 18;

  /// Chamber engraved title tracking (matches chamber ornament headings).
  static const double tableTitleTracking = 2.2;

  static const Duration transitionFast = AppDuration.fast;
  static const Duration transitionNormal = AppDuration.normal;
  static const Duration transitionMedium = AppDuration.medium;
  static const Duration transitionSlow = AppDuration.slow;

  /// Shared ambient loop — one breath across the entire ritual.
  static const Duration ambientLoop = OraclySignatureMaterials.ambientDuration;

  /// Deep handoff between ritual stages (selection → reveal → reading).
  static const Duration ritualHandoff = Duration(milliseconds: 1600);
  static const Duration ritualReadingHandoff = Duration(milliseconds: 1400);

  /// Subtle scale inherited from the previous screen's emotional weight.
  static const double handoffScaleBegin = 1.024;
  static const double handoffScaleSelectionBegin = 1.028;

  /// Screen entry after route handoff — avoids double-fade mud.
  static const Duration screenSettle = Duration(milliseconds: 520);
  static const double screenSettleOpacityBegin = 0.92;

  static const Curve ritualCurve = Curves.easeInOutCubic;
  static const Curve revealCurve = Curves.easeOutCubic;

  /// Canonical tarot screen edges — clears floating shell nav via [AppLayout].
  static EdgeInsets screenPaddingOf(BuildContext context) =>
      AppLayout.scrollContentPadding(
        context,
        top: AppLayout.screenTop,
      );

  /// Horizontal + top only (no bottom). Prefer [screenPaddingOf] for scroll bodies.
  static EdgeInsets get screenPadding =>
      AppLayout.screenPaddingHorizontal.copyWith(
        top: AppLayout.screenTop,
        bottom: 0,
      );
}

/// Ritual flow steps — maps screens to the tarot experience pipeline.
enum TarotFlowStep {
  home,
  deckSelection,
  shuffle,
  cardSelection,
  cardReveal,
  reading,
  cardDetail,
  history,
  premium,
}

extension TarotFlowStepX on TarotFlowStep {
  String get routeName => name;
}
