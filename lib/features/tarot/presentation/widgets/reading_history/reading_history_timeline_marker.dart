/// OR-437 — Timeline day marker for the ritual journal.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class ReadingHistoryTimelineMarker extends StatelessWidget {
  const ReadingHistoryTimelineMarker({
    super.key,
    required this.label,
    required this.isFirst,
    this.isMonth = false,
  });

  final String label;
  final bool isFirst;
  final bool isMonth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        isFirst ? AppSpacing.sm : (isMonth ? AppSpacing.xl : AppSpacing.lg),
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: isMonth ? 10 : 8,
            height: isMonth ? 10 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: isMonth ? 0.9 : 0.75),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldGlow.withValues(alpha: 0.35),
                  blurRadius: isMonth ? 10 : 8,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: AppBorderWidth.hairline,
              color: AppColors.gold.withValues(alpha: isMonth ? 0.28 : 0.18),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: (isMonth
                    ? AppTextStyles.labelLarge
                    : AppTextStyles.labelMedium)
                .copyWith(
              color: AppColors.goldLight.withValues(alpha: isMonth ? 0.92 : 0.78),
              letterSpacing: isMonth ? 1.0 : 0.6,
              fontWeight: isMonth ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
