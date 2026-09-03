/// Onboarding setup form fields — composed from [OnboardingSetupForm].
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/onboarding_copy.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/personality/or_personality.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../../../shared/widgets/oracly_text_action.dart';
import '../../../birth_chart/data/birth_chart_cities.dart';
import '../../../premium/models/personalization_models.dart';
import 'onboarding_birth_city_field.dart';
import 'onboarding_birth_field.dart';
import 'onboarding_choice_chip.dart';

class OnboardingSetupFormContent extends StatelessWidget {
  const OnboardingSetupFormContent({
    super.key,
    required this.nameController,
    required this.birth,
    required this.birthCity,
    required this.language,
    required this.style,
    required this.onPickBirth,
    required this.onPickBirthCity,
    required this.onLanguage,
    required this.onStyle,
    required this.onContinue,
    required this.onSkip,
    this.busy = false,
  });

  final TextEditingController nameController;
  final DateTime? birth;
  final BirthChartCity? birthCity;
  final String language;
  final AiPersonality style;
  final VoidCallback onPickBirth;
  final VoidCallback onPickBirthCity;
  final ValueChanged<String> onLanguage;
  final ValueChanged<AiPersonality> onStyle;
  final VoidCallback? onContinue;
  final VoidCallback? onSkip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Text(OnboardingCopy.setupTitle, style: AppTextStyles.title),
        SizedBox(height: AppSpacing.sm),
        Text(
          OnboardingCopy.setupSubtitle,
          style: ReadingTypography.body(color: AppColors.textSecondary),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          OnboardingCopy.storyWhisper,
          style: ReadingTypography.footnote(color: AppColors.textHint),
        ),
        SizedBox(height: AppSpacing.lg),
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: OnboardingCopy.nameLabel),
        ),
        Text(
          OnboardingCopy.nameHelp,
          style: ReadingTypography.footnote(color: AppColors.textHint),
        ),
        OnboardingBirthField(value: birth, onPick: onPickBirth),
        if (birth != null) ...[
          SizedBox(height: AppSpacing.sm),
          OnboardingBirthCityField(value: birthCity, onPick: onPickBirthCity),
        ],
        SizedBox(height: AppSpacing.md),
        Text(OnboardingCopy.languageLabel, style: AppTextStyles.labelMedium),
        SizedBox(height: AppSpacing.sm),
        OnboardingChoiceWrap(
          options: [for (final o in AppLocale.pickerOptions) (o.$1, o.$2)],
          selected: language,
          onSelect: onLanguage,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          OnboardingCopy.languageHelp,
          style: ReadingTypography.footnote(color: AppColors.textHint),
        ),
        SizedBox(height: AppSpacing.md),
        Text(OnboardingCopy.styleLabel, style: AppTextStyles.labelMedium),
        SizedBox(height: AppSpacing.sm),
        OnboardingChoiceWrap(
          options: [
            for (final s in AiPersonality.values)
              (s.name, OrPersonality.label(s, language)),
          ],
          selected: style.name,
          onSelect: (v) => onStyle(AiPersonality.values.byName(v)),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          OnboardingCopy.styleHelp,
          style: ReadingTypography.footnote(color: AppColors.textHint),
        ),
        SizedBox(height: AppSpacing.xl),
        OraclyButton(
          text: OnboardingCopy.startFirstReading,
          isExpanded: true,
          icon: Icons.arrow_forward_rounded,
          isLoading: busy,
          enabled: !busy,
          onPressed: onContinue,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          OnboardingCopy.firstReadingHint,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(color: AppColors.textHint),
        ),
        OraclyTextAction(label: OnboardingCopy.skip, onPressed: onSkip),
      ],
    );
  }
}
