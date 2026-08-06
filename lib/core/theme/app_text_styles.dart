/// OR-001 — Theme Foundation: premium Material 3 typography.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Material 3 type scale sizes.
abstract final class AppFontSizes {
  AppFontSizes._();

  static const double displayLarge = 40;
  static const double displayMedium = 32;
  static const double displaySmall = 28;
  static const double headlineLarge = 24;
  static const double headlineMedium = 20;
  static const double headlineSmall = 18;
  static const double titleLarge = 18;
  static const double titleMedium = 16;
  static const double titleSmall = 14;
  static const double bodyLarge = 16;
  static const double bodyMedium = 15;
  static const double bodySmall = 13;
  static const double labelLarge = 15;
  static const double labelMedium = 12;
  static const double labelSmall = 11;
  static const double letterWide = 6;
  static const double letterTight = -0.5;
}

/// Premium typography — Cormorant Garamond (display) + Inter (body).
abstract final class AppTextStyles {
  AppTextStyles._();

  static const String displayFontFamily = 'Cormorant Garamond';
  static const String bodyFontFamily = 'Inter';

  static TextStyle _display({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: displayFontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle _body({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Display
  static TextStyle get displayLarge => _display(
        size: AppFontSizes.displayLarge,
        weight: FontWeight.w700,
        color: AppColors.goldLight,
        letterSpacing: AppFontSizes.letterWide,
        height: 1.1,
      );

  static TextStyle get displayMedium => _display(
        size: AppFontSizes.displayMedium,
        letterSpacing: AppFontSizes.letterTight,
        height: 1.12,
      );

  static TextStyle get displaySmall => _display(
        size: AppFontSizes.displaySmall,
        height: 1.15,
      );

  // Headline
  static TextStyle get headlineLarge => _display(
        size: AppFontSizes.headlineLarge,
        height: 1.2,
      );

  static TextStyle get headlineMedium => _display(
        size: AppFontSizes.headlineMedium,
        height: 1.22,
      );

  static TextStyle get headlineSmall => _display(
        size: AppFontSizes.headlineSmall,
        height: 1.25,
      );

  // Title
  static TextStyle get titleLarge => _display(
        size: AppFontSizes.titleLarge,
        letterSpacing: 0.15,
        height: 1.25,
      );

  static TextStyle get titleMedium => _body(
        size: AppFontSizes.titleMedium,
        weight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get titleSmall => _body(
        size: AppFontSizes.titleSmall,
        weight: FontWeight.w600,
        height: 1.35,
      );

  // Body
  static TextStyle get bodyLarge => _body(
        size: AppFontSizes.bodyLarge,
        height: 1.7,
        letterSpacing: 0.05,
      );

  static TextStyle get bodyMedium => _body(
        size: AppFontSizes.bodyMedium,
        color: AppColors.textSecondary,
        height: 1.76,
        letterSpacing: 0.14,
      );

  static TextStyle get bodySmall => _body(
        size: AppFontSizes.bodySmall,
        color: AppColors.textSecondary,
        height: 1.68,
        letterSpacing: 0.12,
      );

  // Label
  static TextStyle get labelLarge => _body(
        size: AppFontSizes.labelLarge,
        weight: FontWeight.w600,
        letterSpacing: 0.6,
        height: 1.2,
      );

  static TextStyle get labelMedium => _body(
        size: AppFontSizes.labelMedium,
        weight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
        height: 1.4,
      );

  static TextStyle get labelSmall => _body(
        size: AppFontSizes.labelSmall,
        weight: FontWeight.w500,
        color: AppColors.textHint,
        letterSpacing: 0.4,
        height: 1.35,
      );

  /// Material [TextTheme] bound to an active [AppColorPalette].
  static TextTheme textTheme(AppColorPalette palette) {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: palette.goldLight),
      displayMedium: displayMedium.copyWith(color: palette.textPrimary),
      displaySmall: displaySmall.copyWith(color: palette.textPrimary),
      headlineLarge: headlineLarge.copyWith(color: palette.textPrimary),
      headlineMedium: headlineMedium.copyWith(color: palette.textPrimary),
      headlineSmall: headlineSmall.copyWith(color: palette.textPrimary),
      titleLarge: titleLarge.copyWith(color: palette.textPrimary),
      titleMedium: titleMedium.copyWith(color: palette.textPrimary),
      titleSmall: titleSmall.copyWith(color: palette.textSecondary),
      bodyLarge: bodyLarge.copyWith(color: palette.textPrimary),
      bodyMedium: bodyMedium.copyWith(color: palette.textSecondary),
      bodySmall: bodySmall.copyWith(color: AppColors.textHint),
      labelLarge: labelLarge.copyWith(color: palette.textPrimary),
      labelMedium: labelMedium.copyWith(color: palette.textSecondary),
      labelSmall: labelSmall.copyWith(color: AppColors.textHint),
    );
  }

  // ── Legacy compatibility aliases ──────────────────────────────

  static TextStyle get hero => displayLarge;
  static TextStyle get logo => displayMedium;
  static TextStyle get heading => headlineLarge;
  static TextStyle get title => titleLarge;
  static TextStyle get subtitle => bodyLarge;
  static TextStyle get body => bodyMedium;
  static TextStyle get caption => labelMedium;
  static TextStyle get button => labelLarge;
  static TextStyle get small => labelSmall;
  static TextStyle get label => labelMedium;
}
