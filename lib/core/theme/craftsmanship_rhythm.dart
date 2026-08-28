/// RC-007 — Invisible craftsmanship rhythm: one scale, one breath.
library;

import 'package:flutter/material.dart';

import 'app_radius.dart';
import 'app_spacing.dart';
import 'oracly_brand_signature.dart';

/// Shared polish tokens — refinements should reference these, not magic numbers.
abstract final class CraftsmanshipRhythm {
  CraftsmanshipRhythm._();

  // Typography — editorial luxury: readable body, restrained tracking.
  static const double bodyLineHeight = 1.76;
  static const double coreLineHeight = 1.82;
  static const double reflectionLineHeight = 1.80;
  static const double displayLineHeight = 1.18;
  static const double titleLineHeight = 1.28;
  static const double microLineHeight = 1.40;
  static const double sectionLabelHeight = 1.30;

  /// Body tracking stays quiet — never stamped.
  static const double bodyLetterSpacing = 0.06;
  static const double displayTracking = 0.85;
  static const double pageTitleTracking = 0.35;
  static const double titleTracking = pageTitleTracking;
  static const double sectionLabelTracking = 1.0;
  static const double eyebrowTracking = 1.15;
  static const double labelTracking = 0.25;
  static const double ctaTracking = 0.2;
  static const double microTracking = 0.2;

  /// Warm secondary inks (ivory-based) — never washed cool gray.
  static const double secondaryInk = 0.80;
  static const double labelInk = 0.86;
  static const double metadataInk = 0.74;
  static const double bodyInk = 0.92;
  static const double titleInk = 0.96;

  /// Space between paragraphs in long-form reading.
  static double get paragraphGap => AppSpacing.sm + AppSpacing.xs;

  // Motion — aligned with immersive navigation (EPIC-025).
  static const Duration appear = Duration(milliseconds: 420);
  static const Duration scroll = Duration(milliseconds: 320);
  static const Duration pulse = Duration(milliseconds: 1800);
  static const Duration think = Duration(milliseconds: 2000);

  static Duration get press => OraclySignatureMotion.press;
  static Duration get pressRelease => OraclySignatureMotion.pressRelease;
  static Curve get curve => OraclySignatureMotion.curve;

  /// Premium scroll feel — soft momentum with gentle overscroll.
  static const ScrollPhysics scrollPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
    decelerationRate: ScrollDecelerationRate.normal,
  );

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
