/// Five equal doors. Size does not prefer one question over another.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/copy/onboarding_copy.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/theme/oracly_reduced_motion.dart';
import 'encounter_interest_label.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../data/encounter_interest_store.dart';

class EncounterInterestWindows extends StatelessWidget {
  const EncounterInterestWindows({
    super.key,
    required this.width,
    required this.selected,
    required this.onToggle,
  });

  final double width;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  static const art = {
    'love': AppAssets.encounterLove,
    'future': AppAssets.encounterFuture,
    'self': AppAssets.encounterSelf,
    'work': AppAssets.encounterWork,
    'curious': AppAssets.encounterCurious,
  };

  @override
  Widget build(BuildContext context) {
    const gap = 14.0;
    final tile = (width - gap) / 2;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final id in EncounterInterests.ids)
          _Window(
            id: id,
            width: tile,
            on: selected.contains(id),
            onTap: () => onToggle(id),
          ),
      ],
    );
  }
}

class _Window extends StatelessWidget {
  const _Window({
    required this.id,
    required this.width,
    required this.on,
    required this.onTap,
  });

  final String id;
  final double width;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = OnboardingCopy.interestLabel(id);
    final arch = BorderRadius.vertical(top: Radius.circular(width * 0.46));
    return OraclyPressable(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: on,
        label: label,
        child: AnimatedScale(
          scale: on && !OraclyReducedMotion.of(context) ? 1.03 : 1,
          duration: const Duration(milliseconds: 220),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: width,
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(width * 0.5),
                bottom: const Radius.circular(16),
              ),
              border: Border.all(
                color: on ? AppColors.goldLight : AppColors.gold.withValues(alpha: 0.32),
                width: on ? 1.5 : 0.7,
              ),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: arch,
                  child: Image.asset(
                    EncounterInterestWindows.art[id]!,
                    width: width - 10,
                    height: (width - 10) * 0.62,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => SizedBox(width: width, height: 64),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.textScalerOf(context).scale(12 * 1.2) * 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: EncounterInterestLabel(label: label),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
