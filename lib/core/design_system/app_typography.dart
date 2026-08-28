/// EPIC-021 — Predefined typography scale.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Font size constants.
abstract final class AppFontSizes {
  AppFontSizes._();

  static const double displayXl = 40;
  static const double displayL = 32;
  static const double headingXl = 28;
  static const double headingL = 24;
  static const double headingM = 20;
  static const double title = 18;
  static const double body = 16;
  static const double caption = 12;
  static const double button = 15;

  /// Restrained wide tracking — engraved accents only, never body.
  static const double letterWide = 0.9;
  static const double letterTight = -0.15;

  // Legacy Material scale aliases.
  static const double displayLarge = displayXl;
  static const double displayMedium = displayL;
  static const double displaySmall = headingXl;
  static const double headlineLarge = headingL;
  static const double headlineMedium = headingM;
  static const double headlineSmall = title;
  static const double titleLarge = title;
  static const double titleMedium = 16;
  static const double titleSmall = 14;
  static const double bodyLarge = 16;
  static const double bodyMedium = body;
  static const double bodySmall = 14;
  static const double labelLarge = button;
  static const double labelMedium = caption;
  static const double labelSmall = 12;
}

/// EPIC-021 typography — Cormorant Garamond + Inter.
abstract final class AppTypography {
  AppTypography._();

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

  static TextStyle get displayXl => _display(
        size: AppFontSizes.displayXl,
        weight: FontWeight.w700,
        color: AppColors.goldLight,
        letterSpacing: AppFontSizes.letterWide,
        height: 1.12,
      );

  static TextStyle get displayL => _display(
        size: AppFontSizes.displayL,
        letterSpacing: AppFontSizes.letterTight,
        height: 1.12,
      );

  static TextStyle get headingXl => _display(
        size: AppFontSizes.headingXl,
        height: 1.15,
      );

  static TextStyle get headingL => _display(
        size: AppFontSizes.headingL,
        height: 1.2,
      );

  static TextStyle get headingM => _display(
        size: AppFontSizes.headingM,
        height: 1.22,
      );

  static TextStyle get title => _display(
        size: AppFontSizes.title,
        letterSpacing: 0.15,
        height: 1.25,
      );

  static TextStyle get body => _body(
        size: AppFontSizes.body,
        color: AppColors.ivory,
        height: 1.76,
        letterSpacing: 0.06,
      );

  static TextStyle get caption => _body(
        size: AppFontSizes.caption,
        weight: FontWeight.w500,
        color: AppColors.ivory.withValues(alpha: 0.72),
        letterSpacing: 0.25,
        height: 1.4,
      );

  static TextStyle get button => _body(
        size: AppFontSizes.button,
        weight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.2,
      );

  static TextTheme textTheme(AppColorPalette palette) {
    return TextTheme(
      displayLarge: displayXl.copyWith(color: palette.goldLight),
      displayMedium: displayL.copyWith(color: palette.textPrimary),
      displaySmall: headingXl.copyWith(color: palette.textPrimary),
      headlineLarge: headingL.copyWith(color: palette.textPrimary),
      headlineMedium: headingM.copyWith(color: palette.textPrimary),
      headlineSmall: title.copyWith(color: palette.textPrimary),
      titleLarge: title.copyWith(color: palette.textPrimary),
      titleMedium: button.copyWith(color: palette.textPrimary),
      titleSmall: caption.copyWith(
        color: palette.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: _body(
        size: AppFontSizes.bodyLarge,
        color: AppColors.ivory.withValues(alpha: 0.92),
        height: 1.76,
        letterSpacing: 0.06,
      ),
      bodyMedium: body.copyWith(
        color: AppColors.ivory.withValues(alpha: 0.88),
      ),
      bodySmall: _body(
        size: AppFontSizes.bodySmall,
        color: AppColors.ivory.withValues(alpha: 0.72),
        height: 1.68,
        letterSpacing: 0.06,
      ),
      labelLarge: button.copyWith(color: palette.textPrimary),
      labelMedium: caption.copyWith(color: palette.textSecondary),
      labelSmall: caption.copyWith(
        color: AppColors.ivory.withValues(alpha: 0.62),
        fontSize: AppFontSizes.labelSmall,
      ),
    );
  }
}

/// Legacy typography alias — existing widgets keep importing [AppTextStyles].
abstract final class AppTextStyles {
  AppTextStyles._();

  static const String displayFontFamily = AppTypography.displayFontFamily;
  static const String bodyFontFamily = AppTypography.bodyFontFamily;

  static TextStyle get displayLarge => AppTypography.displayXl;
  static TextStyle get displayMedium => AppTypography.displayL;
  static TextStyle get displaySmall => AppTypography.headingXl;
  static TextStyle get headlineLarge => AppTypography.headingL;
  static TextStyle get headlineMedium => AppTypography.headingM;
  static TextStyle get headlineSmall => AppTypography.title;
  static TextStyle get titleLarge => AppTypography.title;
  static TextStyle get titleMedium => AppTypography.button;
  static TextStyle get titleSmall => AppTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: AppFontSizes.titleSmall,
      );
  static TextStyle get bodyLarge => AppTypography._body(
        size: AppFontSizes.bodyLarge,
        color: AppColors.ivory.withValues(alpha: 0.92),
        height: 1.76,
        letterSpacing: 0.06,
      );
  static TextStyle get bodyMedium => AppTypography.body;
  static TextStyle get bodySmall => AppTypography._body(
        size: AppFontSizes.bodySmall,
        color: AppColors.ivory.withValues(alpha: 0.86),
        height: 1.68,
        letterSpacing: 0.06,
      );
  static TextStyle get labelLarge => AppTypography.button;
  static TextStyle get labelMedium => AppTypography.caption;
  static TextStyle get labelSmall => AppTypography.caption.copyWith(
        color: AppColors.ivory.withValues(alpha: 0.62),
        fontSize: AppFontSizes.labelSmall,
      );

  static TextTheme textTheme(AppColorPalette palette) =>
      AppTypography.textTheme(palette);

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
