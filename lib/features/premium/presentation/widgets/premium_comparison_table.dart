/// OR-1090 — Free vs Premium comparison table.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/premium_models.dart';

class PremiumComparisonTable extends StatelessWidget {
  const PremiumComparisonTable({
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
                'Ücretsiz vs Premium',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              ClipRRect(
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
                    ),
                    child: Column(
                      children: [
                        _HeaderRow(),
                        ...PremiumCatalogue.comparisonRows.map(
                          (row) => _ComparisonRow(
                            feature: row.$1,
                            free: row.$2,
                            premium: row.$3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.45),
        border: Border(
          bottom: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.18),
            width: AppBorderWidth.hairline,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Özellik',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Ücretsiz',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Premium',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.feature,
    required this.free,
    required this.premium,
  });

  final String feature;
  final bool free;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.08),
            width: AppBorderWidth.hairline,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: _CheckCell(enabled: free)),
          Expanded(child: _CheckCell(enabled: premium, premium: true)),
        ],
      ),
    );
  }
}

class _CheckCell extends StatelessWidget {
  const _CheckCell({required this.enabled, this.premium = false});

  final bool enabled;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return Icon(
      enabled ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
      size: AppSpacing.md,
      color: enabled
          ? (premium ? AppColors.gold : AppColors.textSecondary)
          : AppColors.textHint.withValues(alpha: 0.45),
    );
  }
}
