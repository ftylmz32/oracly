/// SPRINT-002 — Journey step progress indicator.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/birth_chart_copy.dart';

class ChartJourneyProgress extends StatelessWidget {
  const ChartJourneyProgress({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${BirthChartCopy.stepOf} ${current + 1} / $total',
          style: ReadingTypography.sectionLabel(),
        ),
        SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : (current + 1) / total,
            minHeight: 3,
            backgroundColor: AppColors.surface.withValues(alpha: 0.5),
            color: AppColors.gold.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
