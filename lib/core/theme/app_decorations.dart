/// OR-001 — Theme Foundation: shared [BoxDecoration] presets.
library;

import 'package:flutter/material.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_gradients.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_spacing.dart';
import '../design_system/premium_cards/premium_card_shell.dart';
import '../design_system/premium_cards/premium_card_tokens.dart';

/// Reusable premium [BoxDecoration] factories — delegates to card system.
abstract final class AppDecorations {
  AppDecorations._();

  static BoxDecoration premiumCard({BorderRadius? borderRadius}) {
    return BoxDecoration(
      borderRadius: borderRadius ?? AppRadius.s24,
      gradient: AppGradients.primary,
      border: Border.all(
        color: AppColors.gold.withValues(alpha: 0.28),
        width: AppBorderWidth.hairline,
      ),
      boxShadow: PremiumCardDecoration.shadowsFor(PremiumCardGlow.medium),
    );
  }

  static BoxDecoration goldOutline({
    BorderRadius? borderRadius,
    double width = AppBorderWidth.gold,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? AppRadius.s24,
      border: Border.all(color: AppColors.gold, width: width),
    );
  }

  static BoxDecoration mattePanel({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: borderRadius ?? AppRadius.s16,
      border: Border.all(
        color: AppColors.divider,
        width: AppBorderWidth.thin,
      ),
    );
  }

  static BoxDecoration matteSurface({
    Color? color,
    BorderRadius? borderRadius,
  }) =>
      mattePanel(color: color, borderRadius: borderRadius);

  static BoxDecoration luxuryGlass({
    BorderRadius? borderRadius,
    double glowStrength = 1.0,
  }) {
    final glow = glowStrength >= 0.9
        ? PremiumCardGlow.large
        : glowStrength >= 0.7
            ? PremiumCardGlow.medium
            : glowStrength > 0
                ? PremiumCardGlow.small
                : PremiumCardGlow.none;

    return BoxDecoration(
      borderRadius: borderRadius ?? AppRadius.s32,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surfaceElevated.withValues(alpha: 0.94),
          AppColors.surface.withValues(alpha: 0.84),
          AppColors.backgroundSecondary.withValues(alpha: 0.78),
        ],
        stops: const [0.0, 0.55, 1.0],
      ),
      border: Border.all(
        color: AppColors.gold.withValues(alpha: 0.28),
        width: AppBorderWidth.hairline,
      ),
      boxShadow: PremiumCardDecoration.shadowsFor(glow),
    );
  }

  static EdgeInsets contentPadding({EdgeInsets? padding}) {
    return padding ??
        AppSpacing.card.copyWith(
          top: AppSpacing.s12,
          bottom: AppSpacing.s12,
        );
  }
}
