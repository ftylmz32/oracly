/// OR-050 — Premium glass card for daily energy sections.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Frosted glass surface matching the Home design language.
class DailyEnergyGlassCard extends StatelessWidget {
  const DailyEnergyGlassCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.padding,
    this.margin,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lg,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surfaceElevated.withValues(alpha: 0.92),
                  AppColors.surface.withValues(alpha: 0.88),
                ],
              ),
              borderRadius: AppRadius.lg,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.22),
                width: AppBorderWidth.hairline,
              ),
            ),
            child: Padding(
              padding: padding ?? AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Row(
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            size: AppSpacing.md,
                            color: AppColors.goldLight,
                          ),
                          SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          child: Text(
                            title!,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact insight tile inside the four-category grid.
class DailyEnergyInsightTile extends StatelessWidget {
  const DailyEnergyInsightTile({
    super.key,
    required this.icon,
    required this.label,
    required this.body,
  });

  final IconData icon;
  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DailyEnergyGlassCard(
      padding: EdgeInsets.all(AppSpacing.insetCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.matteSurface,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.28),
                    width: AppBorderWidth.hairline,
                  ),
                ),
                child: SizedBox(
                  width: AppSpacing.lg + AppSpacing.xs,
                  height: AppSpacing.lg + AppSpacing.xs,
                  child: Icon(icon, size: AppSpacing.md, color: AppColors.gold),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Lucky attribute chip — number, color, or crystal.
class DailyEnergyLuckyChip extends StatelessWidget {
  const DailyEnergyLuckyChip({
    super.key,
    required this.label,
    required this.value,
    this.swatch,
  });

  final String label;
  final String value;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DailyEnergyGlassCard(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.sm),
            if (swatch != null) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: swatch,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.45),
                    width: AppBorderWidth.hairline,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: swatch!.withValues(alpha: 0.45),
                      blurRadius: AppSpacing.sm,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: AppSpacing.lg,
                  height: AppSpacing.lg,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
            ],
            Text(
              value,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
