/// Gold-bordered choice — reuse press language, never a second chip system.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

class OnboardingChoiceChip extends StatelessWidget {
  const OnboardingChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      borderRadius: AppRadius.round,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: AppRadius.round,
          color: selected
              ? OraclyChrome.violet.withValues(alpha: 0.32)
              : OraclyChrome.cardSurface.withValues(alpha: 0.72),
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: selected ? 0.72 : 0.28),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary.withValues(
              alpha: selected ? 0.96 : 0.72,
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingChoiceWrap extends StatelessWidget {
  const OnboardingChoiceWrap({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          OnboardingChoiceChip(
            label: o.$2,
            selected: o.$1 == selected,
            onTap: () => onSelect(o.$1),
          ),
      ],
    );
  }
}
