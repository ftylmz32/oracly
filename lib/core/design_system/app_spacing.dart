/// EPIC-021 — Approved spacing scale. No custom values outside this list.
///
/// Reference rhythm (use these first): **8 · 12 · 16 · 20 · 24 · 32**
library;

import 'package:flutter/material.dart';

/// Spacing tokens — 4 through 64 only.
abstract final class AppSpacing {
  AppSpacing._();

  static const double s4 = 4;

  /// Reference scale — primary.
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;

  /// Named aliases for the reference rhythm.
  static const double gapXs = s8;
  static const double gapSm = s12;
  static const double gapMd = s16;
  static const double gapLg = s20;
  static const double gapXl = s24;
  static const double gapXxl = s32;

  // Legacy aliases — map to approved scale only.
  static const double xs = s4;
  static const double sm = s8;
  static const double md = s16;
  static const double lg = s24;
  static const double xl = s32;
  static const double xxl = s48;

  static const double insetCard = s20;

  static const EdgeInsets screen =
      EdgeInsets.symmetric(horizontal: s24, vertical: s16);
  static const EdgeInsets screenHorizontal =
      EdgeInsets.symmetric(horizontal: s24);
  static const EdgeInsets card = EdgeInsets.all(insetCard);
}
