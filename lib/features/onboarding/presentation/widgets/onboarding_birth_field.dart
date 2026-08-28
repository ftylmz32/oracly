/// Optional birth date row — used only for Sky / Yıldızname.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/onboarding_copy.dart';
import '../../../../core/l10n/oracly_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

class OnboardingBirthField extends StatelessWidget {
  const OnboardingBirthField({
    super.key,
    required this.value,
    required this.onPick,
  });

  final DateTime? value;
  final VoidCallback onPick;

  String get _label {
    final date = value;
    if (date == null) return OnboardingCopy.birthPick;
    return OraclyFormat.dateNumeric(date);
  }

  @override
  Widget build(BuildContext context) {
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
                    OnboardingCopy.birthLabel,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                Text(_label, style: AppTextStyles.labelMedium),
              ],
            ),
          ),
        ),
        Text(
          OnboardingCopy.birthHelp,
          style: ReadingTypography.footnote(color: AppColors.textHint),
        ),
      ],
    );
  }
}
