/// Shared text / tap fields for soul-mate intake.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

class SoulMateFieldLabel extends StatelessWidget {
  const SoulMateFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.goldLight.withValues(alpha: 0.88),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class SoulMateFieldWhy extends StatelessWidget {
  const SoulMateFieldWhy(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: ReadingTypography.footnote()),
    );
  }
}

class SoulMateTextField extends StatelessWidget {
  const SoulMateTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium.copyWith(
        color: OraclyChrome.cream.withValues(alpha: 0.92),
      ),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textHint.withValues(alpha: 0.75),
        ),
        filled: true,
        fillColor: AppColors.surface.withValues(alpha: 0.42),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.22)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.55)),
        ),
      ),
    );
  }
}

class SoulMateTapField extends StatelessWidget {
  const SoulMateTapField({
    super.key,
    required this.text,
    required this.empty,
    required this.onTap,
  });

  final String text;
  final bool empty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      borderRadius: AppRadius.md,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.42),
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: empty
                      ? AppColors.textHint.withValues(alpha: 0.75)
                      : OraclyChrome.cream.withValues(alpha: 0.92),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
