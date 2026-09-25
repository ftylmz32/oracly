/// Place field + optional skip for birth onboarding.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../copy/birth_chart_copy.dart';
import 'birth_chart_field_button.dart';
import 'birth_chart_place_skip_row.dart';

class BirthChartOnboardingPlaceSection extends StatelessWidget {
  const BirthChartOnboardingPlaceSection({
    super.key,
    required this.placeLabel,
    required this.onPickPlace,
    this.onSkipPlace,
    this.placeSkipped = false,
  });

  final String placeLabel;
  final VoidCallback onPickPlace;
  final VoidCallback? onSkipPlace;
  final bool placeSkipped;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BirthChartFieldButton(
          label: BirthChartCopy.birthPlaceLabel,
          value: placeLabel,
          onTap: onPickPlace,
          muted: placeLabel == BirthChartCopy.birthPlaceHint,
        ),
        BirthChartPlaceSkipRow(
          placeSkipped: placeSkipped,
          onSkipPlace: onSkipPlace,
        ),
        SizedBox(height: AppSpacing.s4),
        Text(
          BirthChartCopy.placeImportance,
          style: OraclyChrome.bodySecondary(size: 11),
        ),
      ],
    );
  }
}
