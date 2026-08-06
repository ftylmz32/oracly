import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Reference-matched tarot typography (serif titles + sans body).
class TarotTypography {
  TarotTypography._();

  static const _serif = 'Georgia';

  static TextStyle screenTitle({Color? color}) => TextStyle(
        fontFamily: _serif,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        letterSpacing: 0.4,
        height: 1.2,
      );

  static TextStyle sectionGold({double size = 17}) => TextStyle(
        fontFamily: _serif,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: AppColors.goldLight,
        letterSpacing: 0.3,
      );

  static TextStyle cardTitleGold({double size = 22}) => TextStyle(
        fontFamily: _serif,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: AppColors.gold,
        letterSpacing: 0.2,
        height: 1.15,
      );

  static TextStyle quote({double size = 13}) => TextStyle(
        fontFamily: _serif,
        fontSize: size,
        fontStyle: FontStyle.italic,
        color: AppColors.gold.withValues(alpha: 0.88),
        height: 1.55,
        letterSpacing: 0.15,
      );

  static TextStyle body({double size = 14}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary.withValues(alpha: 0.92),
        height: 1.75,
        letterSpacing: 0.1,
      );

  static TextStyle captionMuted({double size = 12}) => TextStyle(
        fontSize: size,
        color: AppColors.textSecondary,
        height: 1.5,
        letterSpacing: 0.15,
      );

  static TextStyle spreadTitle({bool selected = false}) => TextStyle(
        fontFamily: _serif,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.goldLight : AppColors.textPrimary,
        height: 1.2,
      );
}
