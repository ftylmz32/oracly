/// TAROT V2 — optional intention field + example chips.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../copy/tarot_polish_copy.dart';

class IntentionQuestionField extends StatelessWidget {
  const IntentionQuestionField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onExampleTap,
    this.placeholder,
    this.examples,
    this.focusNode,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onExampleTap;
  final String? placeholder;
  final List<String>? examples;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          maxLines: 3,
          minLines: 1,
          maxLength: 280,
          buildCounter: (
            context, {
            required currentLength,
            required isFocused,
            maxLength,
          }) =>
              const SizedBox.shrink(),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            height: 1.45,
          ),
          decoration: InputDecoration(
            hintText: placeholder ?? TarotPolishCopy.intentionPlaceholder,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint.withValues(alpha: 0.78),
            ),
            filled: true,
            fillColor: AppColors.surface.withValues(alpha: 0.55),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.md,
              borderSide: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.28),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.md,
              borderSide: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.62),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final example
                in examples ?? TarotPolishCopy.intentionExamples)
              _ExampleChip(
                label: example,
                onTap: () => onExampleTap(example),
              ),
          ],
        ),
      ],
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.round,
          color: AppColors.surface.withValues(alpha: 0.42),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.goldLight.withValues(alpha: 0.88),
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
