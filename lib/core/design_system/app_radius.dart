/// EPIC-021 — Approved corner radii. 16, 20, 24, 28, 32 only.
library;

import 'package:flutter/material.dart';

/// Corner radius tokens.
abstract final class AppRadius {
  AppRadius._();

  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r28 = 28;
  static const double r32 = 32;

  static const BorderRadius s16 = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius s20 = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius s24 = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius s28 = BorderRadius.all(Radius.circular(r28));
  static const BorderRadius s32 = BorderRadius.all(Radius.circular(r32));

  // Legacy aliases.
  static const BorderRadius md = s16;
  static const BorderRadius lg = s20;
  static const BorderRadius xl = s28;
  static const BorderRadius glass = s32;

  static const double mdValue = r16;
  static const double lgValue = r20;
  static const double xlValue = r28;
  static const double glassValue = r32;
  static const double xsValue = r16;
  static const double smValue = r16;
  static const double xxlValue = r32;
  static const double pillValue = r28;

  static const BorderRadius xs = s16;
  static const BorderRadius sm = s16;
  static const BorderRadius xxl = s32;
  static const BorderRadius round = s28;
}

/// Border width tokens.
abstract final class AppBorderWidth {
  AppBorderWidth._();

  static const double hairline = 0.5;
  static const double thin = 1;
  static const double gold = 1.5;
  static const double emphasis = 2;
}
