/// Compact review of birth inputs before generating Yildizname.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../copy/birth_chart_copy.dart';

class BirthChartReviewCard extends StatelessWidget {
  const BirthChartReviewCard({
    super.key,
    required this.dateLabel,
    required this.timeLabel,
    required this.placeLabel,
  });

  final String dateLabel;
  final String timeLabel;
  final String placeLabel;

  @override
  Widget build(BuildContext context) {
    return OraclyGlassCard(
      borderRadius: OraclyChrome.cardRadius,
      padding: OraclyChrome.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            BirthChartCopy.reviewTitle,
            style: OraclyChrome.sectionLabel(size: 11),
          ),
          SizedBox(height: AppSpacing.s8),
          _row(BirthChartCopy.reviewDateLabel, dateLabel),
          SizedBox(height: AppSpacing.s4),
          _row(BirthChartCopy.reviewTimeLabel, timeLabel),
          SizedBox(height: AppSpacing.s4),
          _row(BirthChartCopy.reviewPlaceLabel, placeLabel),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: OraclyChrome.bodySecondary(size: 12)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyMedium.copyWith(
              color: OraclyChrome.goldLight,
            ),
          ),
        ),
      ],
    );
  }
}