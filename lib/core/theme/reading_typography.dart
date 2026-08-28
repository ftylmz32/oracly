/// RC-008 — Global editorial typography: one luxury hierarchy everywhere.
library;

import 'package:flutter/material.dart';

import '../design_system/oracly_chrome.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'craftsmanship_rhythm.dart';

/// Semantic reading styles — one editorial hierarchy across every chamber.
///
abstract final class ReadingTypography {
  ReadingTypography._();

  static Color get _ivory => OraclyChrome.ivory;
  static Color get _gold => AppColors.goldLight;
  /// DISPLAY — hero / ritual titles (gold accent, restrained tracking).
  static TextStyle display({Color? color}) => AppTextStyles.displaySmall.copyWith(
        color: color ?? _gold.withValues(alpha: 0.96),
        fontWeight: FontWeight.w600,
        letterSpacing: CraftsmanshipRhythm.displayTracking,
        height: CraftsmanshipRhythm.displayLineHeight,
      );

  /// PAGE TITLE — screen / chamber titles (warm ivory).
  static TextStyle pageTitle({Color? color}) =>
      AppTextStyles.headlineMedium.copyWith(
        color: color ?? _ivory.withValues(alpha: CraftsmanshipRhythm.titleInk),
        fontWeight: FontWeight.w600,
        letterSpacing: CraftsmanshipRhythm.pageTitleTracking,
        height: CraftsmanshipRhythm.titleLineHeight,
      );

  static TextStyle title({Color? color}) => pageTitle(color: color);

  /// SECTION TITLE — engraved gold headings.
  static TextStyle sectionTitle({Color? color, double fontSize = 13}) =>
      AppTextStyles.labelMedium.copyWith(
        color: color ?? _gold.withValues(alpha: 0.92),
        fontWeight: FontWeight.w600,
        letterSpacing: CraftsmanshipRhythm.sectionLabelTracking,
        height: CraftsmanshipRhythm.sectionLabelHeight,
        fontSize: fontSize,
        fontFamily: AppTextStyles.displayFontFamily,
      );

  static TextStyle section({Color? color, double fontSize = 13}) =>
      sectionTitle(color: color, fontSize: fontSize);

  static TextStyle sectionLabel({Color? color, double fontSize = 13}) =>
      sectionTitle(color: color, fontSize: fontSize);

  /// EYEBROW — quiet overline above a title (gold, not tiny).
  static TextStyle eyebrow({Color? color, double fontSize = 12}) =>
      AppTextStyles.labelMedium.copyWith(
        color: color ?? AppColors.gold.withValues(alpha: 0.90),
        fontWeight: FontWeight.w600,
        letterSpacing: CraftsmanshipRhythm.eyebrowTracking,
        height: CraftsmanshipRhythm.sectionLabelHeight,
        fontSize: fontSize,
      );

  /// BODY — primary reading (warm ivory, never tiny).
  static TextStyle body({Color? color}) => AppTextStyles.bodyLarge.copyWith(
        color: color ?? _ivory.withValues(alpha: CraftsmanshipRhythm.bodyInk),
        height: CraftsmanshipRhythm.bodyLineHeight,
        letterSpacing: CraftsmanshipRhythm.bodyLetterSpacing,
        fontWeight: FontWeight.w400,
      );

  static TextStyle bodySmall({Color? color}) => AppTextStyles.bodyMedium.copyWith(
        color: color ?? _ivory.withValues(alpha: 0.86),
        height: CraftsmanshipRhythm.bodyLineHeight,
        letterSpacing: CraftsmanshipRhythm.bodyLetterSpacing,
        fontSize: 15,
      );

  static TextStyle bodyCore({Color? color}) => body(color: color).copyWith(
        height: CraftsmanshipRhythm.coreLineHeight,
        fontWeight: FontWeight.w500,
      );

  /// SECONDARY — supporting copy (warm ivory fade, never washed gray).
  static TextStyle secondary({Color? color}) => body(color: color).copyWith(
        color: color ??
            _ivory.withValues(alpha: CraftsmanshipRhythm.secondaryInk),
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w400,
        fontSize: 15,
      );

  /// CTA — button / action labels.
  static TextStyle cta({Color? color}) => AppTextStyles.labelLarge.copyWith(
        color: color ?? AppColors.nearBlack,
        fontWeight: FontWeight.w600,
        letterSpacing: CraftsmanshipRhythm.ctaTracking,
        height: 1.15,
        fontSize: 15,
      );

  /// LABEL — control / chip / field labels.
  static TextStyle label({Color? color}) => AppTextStyles.labelMedium.copyWith(
        color: color ?? _ivory.withValues(alpha: CraftsmanshipRhythm.labelInk),
        fontWeight: FontWeight.w500,
        letterSpacing: CraftsmanshipRhythm.labelTracking,
        height: 1.35,
        fontSize: 13,
        fontStyle: FontStyle.normal,
      );

  /// METADATA — timestamps, counts, quiet chrome.
  static TextStyle metadata({Color? color}) =>
      AppTextStyles.labelMedium.copyWith(
        color: color ??
            _ivory.withValues(alpha: CraftsmanshipRhythm.metadataInk),
        fontWeight: FontWeight.w500,
        letterSpacing: CraftsmanshipRhythm.microTracking,
        height: CraftsmanshipRhythm.microLineHeight,
        fontSize: 12,
        fontStyle: FontStyle.normal,
      );

  static TextStyle micro({Color? color}) => metadata(color: color);

  /// Short atmospheric italic — never for giant paragraphs.
  static TextStyle reflection({Color? color}) => body(color: color).copyWith(
        height: CraftsmanshipRhythm.reflectionLineHeight,
        fontStyle: FontStyle.italic,
      );

  static TextStyle opening({Color? color}) => reflection(
        color: color ??
            _ivory.withValues(alpha: CraftsmanshipRhythm.secondaryInk),
      );

  static TextStyle cardTitle({Color? color}) => title(color: color);

  /// Short disclaimer / whisper — italic atmosphere only.
  static TextStyle footnote({Color? color}) => secondary(color: color).copyWith(
        fontStyle: FontStyle.italic,
        fontSize: 14,
      );

  static TextStyle closing({Color? color}) => reflection(
        color: color ??
            _ivory.withValues(alpha: CraftsmanshipRhythm.metadataInk),
      );
}
