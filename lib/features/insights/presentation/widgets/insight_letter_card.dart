/// SPRINT-004 — Single insight paragraph in letter style.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../models/insight.dart';
import '../../models/insight_category.dart';

class InsightLetterCard extends StatelessWidget {
  const InsightLetterCard({
    super.key,
    required this.insight,
    required this.onMore,
    this.entrance = 1,
  });

  final Insight insight;
  final VoidCallback onMore;
  final double entrance;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance.clamp(0.0, 1.0)) * 12;

    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      insight.category.sectionLabel,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textHint,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onMore,
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: AppColors.textHint.withValues(alpha: 0.7),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                insight.title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                insight.body,
                style: ReadingTypography.reflection(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
