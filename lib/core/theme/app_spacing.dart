/// OR-001 — Theme Foundation: spacing and motion tokens.
library;

import 'package:flutter/material.dart';

/// Spacing scale — the only approved layout increments in Oracly UI.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Default inner padding for cards and panels.
  static const double insetCard = md + sm - xs;

  static const EdgeInsets screen =
      EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets screenHorizontal =
      EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets card = EdgeInsets.all(insetCard);
}

/// Motion durations shared across transitions and micro-interactions.
abstract final class AppDuration {
  AppDuration._();

  static const Duration fast = Duration(milliseconds: 240);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration medium = Duration(milliseconds: 520);
  static const Duration slow = Duration(milliseconds: 680);
  static const Duration breathe = Duration(milliseconds: 4800);

  /// RC-007 — micro-interaction timings shared across surfaces.
  static const Duration appear = Duration(milliseconds: 340);
  static const Duration scroll = Duration(milliseconds: 320);
  static const Duration pulse = Duration(milliseconds: 1200);
  static const Duration think = Duration(milliseconds: 2000);
}
