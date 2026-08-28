/// Visual fields for the birth-chart onboarding form.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/hero_art/hero_art.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../copy/birth_chart_copy.dart';
import 'birth_chart_field_button.dart';
import 'birth_chart_review_card.dart';
import 'birth_chart_time_choice_row.dart';

class BirthChartOnboardingForm extends StatelessWidget {
  const BirthChartOnboardingForm({
    super.key,
    required this.dateLabel,
    required this.timeLabel,
    required this.placeLabel,
    required this.submitLabel,
    required this.onPickDate,
    required this.onPickTime,
    required this.onPickPlace,
    required this.onSubmit,
    required this.timeKnown,
    required this.onTimeKnown,
    required this.onTimeUnknown,
    this.showTimeField = false,
    this.timeNote,
    this.showReview = false,
    this.reviewTimeLabel,
    this.onCancel,
  });

  final String dateLabel;
  final String timeLabel;
  final String placeLabel;
  final String submitLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onPickPlace;
  final VoidCallback onSubmit;
  final bool? timeKnown;
  final VoidCallback onTimeKnown;
  final VoidCallback onTimeUnknown;
  final bool showTimeField;
  final String? timeNote;
  final bool showReview;
  final String? reviewTimeLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        0,
        AppSpacing.s8,
        0,
        AppLayout.scrollBottomInset(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: HeroBirthChart(size: 112)),
          SizedBox(height: OraclyChrome.sectionGap),
          Text(
            BirthChartCopy.personalizeEmpty,
            style: ReadingTypography.cardTitle(),
          ),
          SizedBox(height: AppSpacing.s4),
          Text(
            BirthChartCopy.onboardingDescription,
            style: OraclyChrome.bodySecondary(size: 13),
          ),
          SizedBox(height: AppSpacing.s8),
          Text(
            BirthChartCopy.trustNote,
            style: OraclyChrome.bodySecondary(size: 11),
          ),
          SizedBox(height: OraclyChrome.sectionGap),
          BirthChartFieldButton(
            label: BirthChartCopy.birthDateLabel,
            value: dateLabel,
            onTap: onPickDate,
          ),
          SizedBox(height: AppSpacing.s12),
          BirthChartTimeChoiceRow(
            known: timeKnown,
            onKnown: onTimeKnown,
            onUnknown: onTimeUnknown,
          ),
          if (showTimeField) ...[
            SizedBox(height: AppSpacing.s8),
            BirthChartFieldButton(
              label: BirthChartCopy.birthTimeLabel,
              value: timeLabel,
              onTap: onPickTime,
            ),
          ],
          if (timeNote != null) ...[
            SizedBox(height: AppSpacing.s4),
            Text(timeNote!, style: OraclyChrome.bodySecondary(size: 11)),
          ],
          SizedBox(height: AppSpacing.s8),
          BirthChartFieldButton(
            label: BirthChartCopy.birthPlaceLabel,
            value: placeLabel,
            onTap: onPickPlace,
            muted: placeLabel == BirthChartCopy.birthPlaceHint,
          ),
          SizedBox(height: AppSpacing.s4),
          Text(
            BirthChartCopy.placeImportance,
            style: OraclyChrome.bodySecondary(size: 11),
          ),
          if (showReview) ...[
            SizedBox(height: AppSpacing.s16),
            BirthChartReviewCard(
              dateLabel: dateLabel,
              timeLabel: reviewTimeLabel ?? timeLabel,
              placeLabel: placeLabel,
            ),
          ],
          SizedBox(height: AppSpacing.s24),
          OraclyButton(
            text: submitLabel,
            isExpanded: true,
            onPressed: onSubmit,
          ),
          if (onCancel != null) ...[
            SizedBox(height: AppSpacing.s8),
            OraclyButton(
              text: BirthChartCopy.cancelEdit,
              type: OraclyButtonType.ghost,
              isExpanded: true,
              onPressed: onCancel,
            ),
          ],
        ],
      ),
    );
  }
}
