/// RC-008 — Reading typography presets for calm, downward eye movement.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'craftsmanship_rhythm.dart';
import 'oracly_brand_signature.dart';

/// Semantic reading styles — one rhythm across reading, chat, ritual, history.
abstract final class ReadingTypography {
  ReadingTypography._();

  static TextStyle body({Color? color}) => AppTextStyles.bodyMedium.copyWith(
        color: color ?? AppColors.textSecondary,
        height: CraftsmanshipRhythm.bodyLineHeight,
        letterSpacing: CraftsmanshipRhythm.bodyLetterSpacing,
      );

  static TextStyle bodySmall({Color? color}) => AppTextStyles.bodySmall.copyWith(
        color: color ?? AppColors.textSecondary,
        height: CraftsmanshipRhythm.bodyLineHeight,
        letterSpacing: CraftsmanshipRhythm.bodyLetterSpacing,
      );

  static TextStyle bodyCore({Color? color}) => body(color: color).copyWith(
        height: CraftsmanshipRhythm.coreLineHeight,
        fontWeight: FontWeight.w500,
      );

  static TextStyle reflection({Color? color}) => body(color: color).copyWith(
        height: CraftsmanshipRhythm.reflectionLineHeight,
        fontStyle: FontStyle.italic,
      );

  /// Opening card subtitle — invites curiosity before meaning.
  static TextStyle opening({Color? color}) => reflection(
        color: color ?? AppColors.textMuted,
      ).copyWith(
        letterSpacing: CraftsmanshipRhythm.bodyLetterSpacing + 0.04,
      );

  static TextStyle sectionLabel({Color? color, double fontSize = 12}) =>
      OraclySignatureTypography.sectionLabel(fontSize: fontSize).copyWith(
        color: color ?? AppColors.goldLight.withValues(alpha: 0.86),
        fontWeight: FontWeight.w600,
      );

  static TextStyle cardTitle({Color? color}) =>
      AppTextStyles.headlineSmall.copyWith(
        color: color ?? AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.28,
      );

  static TextStyle footnote({Color? color}) => AppTextStyles.bodySmall.copyWith(
        color: color ?? AppColors.textHint,
        height: CraftsmanshipRhythm.bodyLineHeight,
        letterSpacing: CraftsmanshipRhythm.bodyLetterSpacing,
        fontStyle: FontStyle.italic,
      );

  static TextStyle closing({Color? color}) => reflection(
        color: color ?? AppColors.textMuted,
      );
}
