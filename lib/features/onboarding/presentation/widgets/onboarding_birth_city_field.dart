/// Optional birth city picker — used only for birth-based chart flavor.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/onboarding_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../birth_chart/copy/birth_chart_copy.dart';
import '../../../birth_chart/data/birth_chart_cities.dart';

class OnboardingBirthCityField extends StatelessWidget {
  const OnboardingBirthCityField({
    super.key,
    required this.value,
    required this.onPick,
  });

  final BirthChartCity? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final label = value?.nameTr ?? BirthChartCopy.birthPlaceHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OraclyPressable(
          onTap: onPick,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    BirthChartCopy.birthPlaceLabel,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                Text(label, style: AppTextStyles.labelMedium),
              ],
            ),
          ),
        ),
        Text(
          OnboardingCopy.birthCityHelp,
          style: ReadingTypography.footnote(color: AppColors.textHint),
        ),
      ],
    );
  }
}
