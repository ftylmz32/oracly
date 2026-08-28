/// EPIC-021 — Five reusable luxury shadows.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shadow metric tokens.
abstract final class AppShadowMetrics {
  AppShadowMetrics._();

  static const double softBlur = 24;
  static const Offset softOffset = Offset(0, 8);
  static const double luxuryBlur = 40;
  static const Offset luxuryOffset = Offset(0, 16);
  static const double elevatedBlur = 32;
  static const Offset elevatedOffset = Offset(0, 12);
  static const double depthBlur = 48;
  static const Offset depthOffset = Offset(0, 20);
  static const double ambientBlur = 56;
  static const double thumbThickness = 4;

  // Legacy tarot widget aliases.
  static const double iconBlur = 12;
  static const double goldBlur = 24;
  static const double goldSpread = 1;
  static const double cardGlowBlur = 16;
}

/// Soft luxury shadows — large blur, low opacity.
abstract final class AppShadows {
  AppShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: AppShadowMetrics.softBlur,
      offset: AppShadowMetrics.softOffset,
    ),
  ];

  static const List<BoxShadow> luxury = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: AppShadowMetrics.luxuryBlur,
      offset: AppShadowMetrics.luxuryOffset,
    ),
    BoxShadow(
      color: Color(0x1A6E52FF),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: AppShadowMetrics.elevatedBlur,
      offset: AppShadowMetrics.elevatedOffset,
    ),
  ];

  static const List<BoxShadow> depth = [
    BoxShadow(
      color: Color(0x59000000),
      blurRadius: AppShadowMetrics.depthBlur,
      offset: AppShadowMetrics.depthOffset,
    ),
  ];

  static const List<BoxShadow> ambient = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: AppShadowMetrics.ambientBlur,
      spreadRadius: -8,
    ),
  ];

  // Legacy aliases used across the app.
  static const List<BoxShadow> card = luxury;

  static const List<BoxShadow> goldGlow = [
    BoxShadow(
      color: AppColors.glowGold,
      blurRadius: 24,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Color(0x1FD8B46A),
      blurRadius: 16,
    ),
  ];

  static const List<BoxShadow> iconGlow = [
    BoxShadow(
      color: Color(0x40F4D58D),
      blurRadius: 12,
    ),
  ];
}
