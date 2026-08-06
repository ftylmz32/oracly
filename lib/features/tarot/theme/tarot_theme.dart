/// OR-1000 — Tarot module theme extensions over the global Oracly theme.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/oracly_brand_signature.dart';

/// Tarot-specific visual presets — reuses Home palette and typography.
abstract final class TarotTheme {
  TarotTheme._();

  static BoxDecoration glassCard({BorderRadius? radius}) {
    return BoxDecoration(
      borderRadius: radius ?? AppRadius.lg,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.surfaceElevated.withValues(alpha: 0.92),
          AppColors.surface.withValues(alpha: 0.88),
        ],
      ),
      border: Border.all(
        color: AppColors.gold.withValues(alpha: 0.22),
        width: AppBorderWidth.hairline,
      ),
      boxShadow: AppShadows.soft,
    );
  }

  static TextStyle get sectionTitle => OraclySignatureTypography.sectionLabel().copyWith(
        color: AppColors.goldLight,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyMuted => AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondary,
        height: CraftsmanshipRhythm.bodyLineHeight,
        letterSpacing: CraftsmanshipRhythm.bodyLetterSpacing,
      );

  static TextStyle get placeholderTitle => AppTextStyles.headlineMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get placeholderCaption => AppTextStyles.labelMedium.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      );

  static BoxDecoration primaryButtonDecoration({bool enabled = true}) {
    return BoxDecoration(
      borderRadius: AppRadius.round,
      gradient: LinearGradient(
        colors: enabled
            ? [AppColors.goldLight, AppColors.gold]
            : [
                AppColors.goldLight.withValues(alpha: 0.35),
                AppColors.gold.withValues(alpha: 0.35),
              ],
      ),
      boxShadow: enabled ? AppShadows.goldGlow : null,
    );
  }

  static BoxDecoration secondaryButtonDecoration({bool enabled = true}) {
    final base = AppDecorations.premiumCard(borderRadius: AppRadius.round);
    return base.copyWith(
      border: Border.all(
        color: AppColors.gold.withValues(alpha: enabled ? 0.38 : 0.18),
        width: AppBorderWidth.hairline,
      ),
    );
  }
}
