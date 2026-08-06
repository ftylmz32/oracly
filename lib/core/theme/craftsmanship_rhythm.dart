/// RC-007 — Invisible craftsmanship rhythm: one scale, one breath.
library;

import 'package:flutter/material.dart';

import 'app_radius.dart';
import 'app_spacing.dart';
import 'oracly_brand_signature.dart';

/// Shared polish tokens — refinements should reference these, not magic numbers.
abstract final class CraftsmanshipRhythm {
  CraftsmanshipRhythm._();

  // Typography — reading and conversation body share one breath.
  static const double bodyLineHeight = 1.76;
  static const double coreLineHeight = 1.82;
  static const double reflectionLineHeight = 1.80;
  static const double bodyLetterSpacing = 0.14;
  static const double sectionLabelTracking = 2.2;
  static const double sectionLabelHeight = 1.35;

  /// Space between paragraphs in long-form reading.
  static double get paragraphGap => AppSpacing.sm + AppSpacing.xs;

  // Motion — aligned with OraclySignatureMotion where possible.
  static const Duration appear = Duration(milliseconds: 340);
  static const Duration scroll = Duration(milliseconds: 320);
  static const Duration pulse = Duration(milliseconds: 1200);
  static const Duration think = Duration(milliseconds: 2000);

  static Duration get press => OraclySignatureMotion.press;
  static Duration get pressRelease => OraclySignatureMotion.pressRelease;
  static Curve get curve => OraclySignatureMotion.curve;

  // Spacing — vertical beats expressed on the approved scale.
  static double get afterCard => AppSpacing.lg - AppSpacing.xs;
  static double get afterTitle => AppSpacing.sm + AppSpacing.xs;
  static double get afterKeywords => AppSpacing.lg - AppSpacing.xs;
  static double get beforeInterpretation => AppSpacing.xl;
  static double get betweenSections => AppSpacing.lg - AppSpacing.xs;
  static double get betweenActs => AppSpacing.xl + AppSpacing.xs;
  static double get beforeReflection => AppSpacing.xxl;
  static double get afterReflection => AppSpacing.xxl - AppSpacing.xs;
  static double get beforeFooter => AppSpacing.sm;

  // Glass surfaces — one radius family.
  static double get glassRadius => AppRadius.glassValue;
  static EdgeInsets get glassPadding => AppSpacing.card;
}
