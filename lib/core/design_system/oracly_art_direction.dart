/// Final art direction — one mix, one chrome family, chamber tints stay local.
/// Governance: docs/GLOBAL_VISUAL_QUALITY_SYSTEM.md
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'oracly_chrome.dart';

/// 70% dark calm · 20% violet/navy · 10% antique gold (+ restrained amber).
abstract final class OraclyArtDirection {
  OraclyArtDirection._();

  static const Color calm = AppColors.nearBlack;
  static const Color navy = AppColors.midnightNavy;
  static const Color violet = AppColors.primaryPurple;
  static const Color gold = AppColors.gold;
  static const Color ivory = AppColors.ivory;
  static const Color amber = AppColors.amber;

  static const double goldFillMax = 0.11;
  static const double goldGlowMax = 0.24;
  static const double violetGlowMax = 0.18;
  static const double amberGlowMax = 0.14;
  static const double goldBorderDefault = 0.34;
  static const double goldBorderEmphasis = 0.50;

  static const List<double> phoneWidths = [
    360,
    375,
    390,
    411,
    430,
    600,
  ];

  static BorderRadius get card => OraclyChrome.cardRadius;
  static BorderRadius get hero => OraclyChrome.heroRadius;
  static BorderRadius get pill => OraclyChrome.pillRadius;

  static const List<double> radii = [
    AppRadius.r16,
    AppRadius.r20,
    AppRadius.r24,
    AppRadius.r28,
    AppRadius.r32,
  ];

  static double clampGoldGlow(double alpha) =>
      alpha.clamp(0.0, goldGlowMax);

  static double clampVioletGlow(double alpha) =>
      alpha.clamp(0.0, violetGlowMax);

  static double clampAmberGlow(double alpha) =>
      alpha.clamp(0.0, amberGlowMax);
}
