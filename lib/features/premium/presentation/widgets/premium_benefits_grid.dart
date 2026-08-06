/// OR-1090 — Premium benefits glass grid.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../models/premium_models.dart';

class PremiumBenefitsGrid extends StatelessWidget {
  const PremiumBenefitsGrid({
    super.key,
    required this.entrance,
  });

  final double entrance;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance) * 18;
    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                PremiumCatalogue.benefitsSectionTitle,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              ...PremiumCatalogue.benefits.map(
                (b) => Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _BenefitCard(benefit: b),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.benefit});

  final PremiumBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.lg,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surfaceElevated.withValues(alpha: 0.92),
                AppColors.surface.withValues(alpha: 0.84),
              ],
            ),
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.24),
              width: AppBorderWidth.hairline,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Padding(
            padding: AppSpacing.card,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.35),
                        AppColors.purpleDark,
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      width: AppBorderWidth.hairline,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      benefit.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benefit.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        benefit.description,
                        style: ReadingTypography.bodySmall(),
                      ),
                    ],
                  ),
                ),
                Icon(
                  benefit.icon,
                  color: AppColors.gold.withValues(alpha: 0.55),
                  size: AppSpacing.lg,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
