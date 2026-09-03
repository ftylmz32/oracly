/// Reference Home layout tokens — dashboard fit + scroll fallback sizes.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_design_system.dart';
import 'home_viewport_layout.dart';

export 'home_viewport_layout.dart';

/// Pixel-aligned Home measurements from the master reference collage.
///
/// Sections keep readable preferred heights; short viewports scroll instead
/// of compressing the stack into Expanded flex.
abstract final class HomeReferenceTokens {
  HomeReferenceTokens._();

  /// Side gutters — ~20 logical px, equal left/right.
  static const double screenHorizontal = AppSpacing.s20;
  static const double screenTop = AppSpacing.s4;

  /// Minimum readable discovery tile height (scroll layout).
  static const double moduleTileMinHeight = 104;

  static const BorderRadius heroRadius = AppRadius.s24;
  static const BorderRadius moduleRadius = AppRadius.s20;
  static const BorderRadius premiumRadius = AppRadius.s20;

  static const double moduleTitleSize = 14;
  static const double moduleCaptionSize = 10;
  static const double heroButtonMinWidth = 120;

  // Legacy tokens — unused reference widgets still compile against these.
  static const double sectionLabelToContent = AppSpacing.s8;
  static const double orGuideMinHeight = 118;
  static const BorderRadius orGuideRadius = AppRadius.s20;
  static const EdgeInsets orGuidePadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const double orGuideIconWell = 44;
  static const double orGuideIconSize = 24;
  static const double discoverCardMinHeight = 96;
  static const double discoverGap = AppSpacing.s8;
  static const BorderRadius discoverRadius = AppRadius.s20;
  static const EdgeInsets discoverPadding =
      EdgeInsets.fromLTRB(16, 14, 16, 12);
  static const double discoverIconSize = 22;
  static const BorderRadius dailyRadius = AppRadius.s20;
  static const EdgeInsets dailyPadding = EdgeInsets.fromLTRB(16, 12, 0, 12);
  static const double dailyIllustrationMaxHeight = 120;
  static const double dailyTextToButtons = AppSpacing.s8;
  static const double dailyTitleToBody = AppSpacing.s8;

  /// Resolves preferred metrics from a screen-height hint.
  static HomeViewportLayout layoutFor(double maxHeight) {
    return HomeViewportLayout.resolve(maxHeight);
  }
}
