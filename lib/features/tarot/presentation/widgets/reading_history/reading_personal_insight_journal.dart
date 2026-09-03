/// OR-439 — Personal insight journal page — observational, not analytical.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/transparency_copy.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/domain/models/personal_insight_report.dart';
import '../../../../../core/domain/models/personal_insight_theme.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/reading_typography.dart';

/// Gentle reflection card for reading history — feels like a journal page.
class ReadingPersonalInsightJournal extends StatelessWidget {
  const ReadingPersonalInsightJournal({
    super.key,
    required this.report,
    this.entrance = 1,
  });

  final PersonalInsightReport report;
  final double entrance;

  @override
  Widget build(BuildContext context) {
    if (!report.hasThemePattern && !report.hasMonthlyReflection) {
      return const SizedBox.shrink();
    }

    final slide = (1 - entrance) * 16;

    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lg,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceElevated.withValues(alpha: 0.90),
                  AppColors.surface.withValues(alpha: 0.84),
                ],
              ),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.24),
                width: AppBorderWidth.hairline,
              ),
            ),
            child: Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 18,
                        color: AppColors.goldLight.withValues(alpha: 0.82),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          OraclyL10n.t('history.journey'),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (report.hasMonthlyReflection) ...[
                    SizedBox(height: AppSpacing.md),
                    Text(
                      report.monthlyReflection!.monthLabel,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textHint,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      report.monthlyReflection!.observation,
                      style: ReadingTypography.reflection(),
                    ),
                  ],
                  if (report.hasThemePattern) ...[
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      OraclyL10n.t('history.journey_echo_themes'),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final echo in report.recurringThemes)
                          _ThemeWhisper(theme: echo.theme),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      TransparencyCopy.insightFootnote,
                      style: ReadingTypography.footnote(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeWhisper extends StatelessWidget {
  const _ThemeWhisper({required this.theme});

  final PersonalInsightTheme theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.round,
        color: AppColors.primary.withValues(alpha: 0.38),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.18),
          width: AppBorderWidth.hairline,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          theme.label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.goldLight.withValues(alpha: 0.78),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
