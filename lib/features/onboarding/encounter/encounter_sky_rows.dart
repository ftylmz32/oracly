/// Quiet birth rows — date, known time, city.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/onboarding_copy.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_pressable.dart';

class EncounterSkyRow extends StatelessWidget {
  const EncounterSkyRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.goldLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EncounterTimeChoice extends StatelessWidget {
  const EncounterTimeChoice({
    super.key,
    required this.known,
    required this.onKnow,
    required this.onUnknown,
  });

  final bool known;
  final VoidCallback onKnow;
  final VoidCallback onUnknown;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Chip(
            label: OnboardingCopy.skyKnow,
            on: known,
            onTap: onKnow,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            label: OnboardingCopy.skyUnknown,
            on: !known,
            onTap: onUnknown,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          color: on ? AppColors.gold.withValues(alpha: 0.14) : const Color(0x00000000),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: on ? AppColors.goldLight : AppColors.gold.withValues(alpha: 0.4),
          ),
        ),
        child: Text(label, style: AppTextStyles.labelMedium),
      ),
    );
  }
}
