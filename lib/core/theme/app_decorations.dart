/// OR-001 — Theme Foundation: gradients and shared [BoxDecoration] presets.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'oracly_brand_signature.dart';

/// Matte gradients for premium surfaces.
abstract final class AppGradients {
  AppGradients._();

  static const LinearGradient background = LinearGradient(
    begin: Alignment(-0.2, -1),
    end: Alignment(0.3, 1.1),
    colors: [
      AppColors.secondary,
      AppColors.background,
      AppColors.background,
    ],
    stops: [0, 0.45, 1],
  );

  static const LinearGradient matteCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfaceElevated, AppColors.surface],
  );

  static const LinearGradient matteSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surfaceElevated, AppColors.surface],
  );

  static const LinearGradient goldBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.goldLight, AppColors.gold, AppColors.gold],
  );

  static LinearGradient glass = OraclySignatureChamber.crystalBody();
}

/// Reusable premium [BoxDecoration] factories.
abstract final class AppDecorations {
  AppDecorations._();

  static BoxDecoration premiumCard({BorderRadius? borderRadius}) {
    return BoxDecoration(
      gradient: AppGradients.matteCard,
      borderRadius: borderRadius ?? AppRadius.lg,
      border: Border.all(
        color: AppColors.matteBorder,
        width: AppBorderWidth.thin,
      ),
      boxShadow: AppShadows.card,
    );
  }

  static BoxDecoration goldOutline({
    BorderRadius? borderRadius,
    double width = AppBorderWidth.gold,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? AppRadius.lg,
      border: Border.all(color: AppColors.gold, width: width),
    );
  }

  static BoxDecoration mattePanel({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: borderRadius ?? AppRadius.md,
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

  static EdgeInsets contentPadding({EdgeInsets? padding}) {
    return padding ??
        AppSpacing.card.copyWith(
          top: AppSpacing.sm + AppSpacing.xs,
          bottom: AppSpacing.sm + AppSpacing.xs,
        );
  }
}
