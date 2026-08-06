/// OR-437 — Emotional keyword chips for journal entries.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class ReadingJournalKeywordChips extends StatelessWidget {
  const ReadingJournalKeywordChips({
    super.key,
    required this.keywords,
    this.compact = false,
  });

  final List<String> keywords;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) return const SizedBox.shrink();

    final visible = compact ? keywords.take(3) : keywords.take(4);

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final word in visible)
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.round,
              color: AppColors.primary.withValues(alpha: 0.42),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.22),
                width: AppBorderWidth.hairline,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppSpacing.sm : AppSpacing.sm + 2,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                word,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.goldLight.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
