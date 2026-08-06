/// OR-1070 / EPIC-012 — Personal journey archive summary card.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/reading_typography.dart';
import 'reading_history_data.dart';

class ReadingHistorySummary extends StatelessWidget {
  const ReadingHistorySummary({
    super.key,
    required this.stats,
  });

  final ReadingHistoryStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lg,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceElevated.withValues(alpha: 0.93),
                  AppColors.surface.withValues(alpha: 0.86),
                ],
              ),
              borderRadius: AppRadius.lg,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.30),
                width: AppBorderWidth.hairline,
              ),
            ),
            child: Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kişisel Arşiv',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.goldLight.withValues(alpha: 0.82),
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (stats.journeyBeginLabel != null) ...[
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Yolculuğun ${stats.journeyBeginLabel}’den beri burada.',
                      style: ReadingTypography.bodySmall(),
                    ),
                  ],
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _MemoryTile(
                          label: 'Kayıtlı An',
                          value: '${stats.totalReadings}',
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MemoryTile(
                          label: 'Bu Ay',
                          value: '${stats.thisMonth}',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _MemoryTile(
                          label: 'Yazılmış Düşünce',
                          value: '${stats.notesWritten}',
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MemoryTile(
                          label: 'Hatıralar',
                          value: '${stats.favoritedMemories}',
                        ),
                      ),
                    ],
                  ),
                  if (stats.recurringCards > 0) ...[
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      '${stats.recurringCards} kart yolculuğunda tekrar belirdi — '
                      'kendi ritmin sessizce oluşuyor olabilir.',
                      style: ReadingTypography.reflection(
                        color: AppColors.goldLight.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        color: AppColors.primary.withValues(alpha: 0.35),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.18),
          width: AppBorderWidth.hairline,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.sm + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
