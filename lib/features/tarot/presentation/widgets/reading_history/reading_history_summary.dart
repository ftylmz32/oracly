/// OR-1070 / EPIC-012 — Personal journey archive summary card.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/l10n/l10n.dart';
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
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    OraclyL10n.t('tarot.history.personal_archive'),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.goldLight.withValues(alpha: 0.82),
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (stats.journeyBeginLabel != null) ...[
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      OraclyL10n.t('tarot.history.journey_since').replaceAll(
                        '{date}',
                        stats.journeyBeginLabel!,
                      ),
                      style: ReadingTypography.bodySmall(),
                    ),
                  ],
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _MemoryTile(
                          label: OraclyL10n.t('tarot.history.recorded_moment'),
                          value: '${stats.totalReadings}',
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MemoryTile(
                          label: OraclyL10n.t('tarot.history.this_month'),
                          value: '${stats.thisMonth}',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _MemoryTile(
                          label: OraclyL10n.t('tarot.hist.notes'),
                          value: '${stats.notesWritten}',
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MemoryTile(
                          label: OraclyL10n.t('tarot.hist.memories'),
                          value: '${stats.favoritedMemories}',
                        ),
                      ),
                    ],
                  ),
                  if (stats.recurringCards > 0) ...[
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      OraclyL10n.t('tarot.hist.recurring')
                          .replaceAll('{n}', '${stats.recurringCards}'),
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
        padding: EdgeInsets.all(AppSpacing.sm),
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
