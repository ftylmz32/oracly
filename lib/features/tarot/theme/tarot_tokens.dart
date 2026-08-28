/// OR-1000 / OR-432 — Tarot module design tokens (aligned with Home design language).
library;

import 'package:flutter/material.dart';

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
  static const double cardAspectRatio = 0.58;
  static const double cardCornerRadius = 12;

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
