/// Birth-time known / unknown choice for Yildizname onboarding.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../onboarding/presentation/widgets/onboarding_choice_chip.dart';
import '../../copy/birth_chart_copy.dart';

class BirthChartTimeChoiceRow extends StatelessWidget {
  const BirthChartTimeChoiceRow({
    super.key,
    required this.known,
    required this.onKnown,
    required this.onUnknown,
  });

  final bool? known;
  final VoidCallback onKnown;
  final VoidCallback onUnknown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          BirthChartCopy.timeChoicePrompt,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        SizedBox(height: AppSpacing.s4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OnboardingChoiceChip(
              label: BirthChartCopy.timeKnownLabel,
              selected: known == true,
              onTap: onKnown,
            ),
            OnboardingChoiceChip(
              label: BirthChartCopy.timeUnknownLabel,
              selected: known == false,
              onTap: onUnknown,
            ),
          ],
        ),
      ],
    );
  }
}