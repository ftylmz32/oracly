/// Ritual spread choice — premium chamber tile, not a list row.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';
import 'tarot_entry_spread_choice.dart';

class TarotEntrySpreadTile extends StatelessWidget {
  const TarotEntrySpreadTile({
    super.key,
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final TarotEntrySpreadChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.goldLight;
    final count = choice.type.cardCount;
    return Semantics(
      button: true,
      selected: selected,
      label: '${choice.title}. ${choice.blurb}',
      child: OraclyPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm + 2,
            AppSpacing.md,
            AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: gold.withValues(alpha: selected ? 0.48 : 0.14),
              width: selected ? 1.15 : 0.9,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: selected ? 0.07 : 0.03),
                AppColors.royalViolet.withValues(alpha: selected ? 0.18 : 0.08),
                const Color(0xFF070510).withValues(alpha: 0.55),
              ],
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _CountMark(count: count, selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.title,
                      style: ReadingTypography.sectionLabel(
                        color: gold.withValues(alpha: selected ? 0.96 : 0.74),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      choice.blurb,
                      style: ReadingTypography.bodySmall(
                        color: AppColors.textSecondary.withValues(
                          alpha: selected ? 0.94 : 0.78,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountMark extends StatelessWidget {
  const _CountMark({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: selected ? 0.42 : 0.18),
        ),
        color: const Color(0xFF0A0614).withValues(alpha: 0.85),
      ),
      child: Text(
        '$count',
        style: ReadingTypography.sectionLabel(
          color: AppColors.goldLight.withValues(alpha: selected ? 0.95 : 0.7),
          fontSize: 13,
        ),
      ),
    );
  }
}
