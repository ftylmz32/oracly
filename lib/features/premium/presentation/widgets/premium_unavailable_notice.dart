/// P0 — Honest unavailable purchase notice for live Premium UI.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Non-purchasing notice — tap does not activate Premium.
class PremiumUnavailableNotice extends StatelessWidget {
  const PremiumUnavailableNotice({
    super.key,
    this.entrance = 1,
    this.onTap,
  });

  final double entrance;

  /// Optional tap (tests / analytics). Must never activate Premium.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance) * 24;
    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.lg,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lg,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.28),
                  ),
                  color: AppColors.surface.withValues(alpha: 0.72),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        PremiumCopy.purchaseUnavailableTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        PremiumCopy.purchaseUnavailableBody,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
