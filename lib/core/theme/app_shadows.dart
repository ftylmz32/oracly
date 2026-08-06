/// OR-001 — Theme Foundation: elevation and glow shadows.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Shadow metric tokens — keeps blur/offset values out of widgets.
abstract final class AppShadowMetrics {
  AppShadowMetrics._();

  static const double softBlur = 20;
  static const Offset softOffset = Offset(0, 10);
  static const double cardBlur = 32;
  static const Offset cardOffset = Offset(0, 16);
  static const double cardGlowBlur = 28;
  static const double goldBlur = 24;
  static const double goldSpread = 1;
  static const double goldSecondaryBlur = 16;
  static const double iconBlur = 12;
  static const double thumbThickness = AppSpacing.sm - AppSpacing.xs;
}

/// Elevation and glow shadows for premium dark UI.
abstract final class AppShadows {
  AppShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x59000000),
      blurRadius: AppShadowMetrics.softBlur,
      offset: AppShadowMetrics.softOffset,
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x6B000000),
      blurRadius: AppShadowMetrics.cardBlur,
      offset: AppShadowMetrics.cardOffset,
    ),
    BoxShadow(
      color: AppColors.glowPurple,
      blurRadius: AppShadowMetrics.cardGlowBlur,
    ),
  ];

  static const List<BoxShadow> goldGlow = [
    BoxShadow(
      color: AppColors.goldGlow,
      blurRadius: AppShadowMetrics.goldBlur,
      spreadRadius: AppShadowMetrics.goldSpread,
    ),
    BoxShadow(
      color: Color(0x1FD4AF37),
      blurRadius: AppShadowMetrics.goldSecondaryBlur,
    ),
  ];

  static const List<BoxShadow> iconGlow = [
    BoxShadow(
      color: Color(0x40D4AF37),
      blurRadius: AppShadowMetrics.iconBlur,
    ),
  ];
}
