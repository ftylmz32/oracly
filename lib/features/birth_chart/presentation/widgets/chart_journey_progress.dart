/// Chart journey step progress — Oracly gold track, never Material bar.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_progress_bar.dart';
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
    final value = total == 0 ? 0.0 : (current + 1) / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${BirthChartCopy.stepOf} ${current + 1} / $total',
          style: ReadingTypography.sectionLabel(),
        ),
        SizedBox(height: AppSpacing.sm),
        OraclyProgressBar(value: value),
      ],
    );
  }
}
