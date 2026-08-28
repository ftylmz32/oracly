/// OR-1070 — Animated spread filter chips.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';
import 'reading_history_data.dart';

class ReadingHistoryFilters extends StatelessWidget {
  const ReadingHistoryFilters({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final HistorySpreadFilter selected;
  final ValueChanged<HistorySpreadFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.xxl,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: HistorySpreadFilter.values.length,
        separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = HistorySpreadFilter.values[index];
          final active = filter == selected;
          return _FilterChip(
            label: filter.displayLabel,
            active: active,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: OraclySignatureMotion.pressRelease,
        curve: OraclySignatureMotion.releaseCurve,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.round,
          gradient: active
              ? LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.35),
                    AppColors.purple.withValues(alpha: 0.28),
                  ],
                )
              : null,
          color: active ? null : AppColors.surface.withValues(alpha: 0.55),
          border: Border.all(
            color: active
                ? AppColors.gold.withValues(alpha: 0.62)
                : AppColors.gold.withValues(alpha: 0.22),
            width: active ? AppBorderWidth.thin : AppBorderWidth.hairline,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.glowPurple.withValues(alpha: 0.22),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: active ? AppColors.goldLight : AppColors.textSecondary,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
