/// SPRINT-004 — Empty state when no observable patterns yet.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/personal_insights_copy.dart';

class InsightsEmptyState extends StatelessWidget {
  const InsightsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 48,
            color: AppColors.goldLight.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            PersonalInsightsCopy.emptyTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.goldLight,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            PersonalInsightsCopy.emptyBody,
            textAlign: TextAlign.center,
            style: ReadingTypography.body(),
          ),
        ],
      ),
    );
  }
}
