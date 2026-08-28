/// One placement or theme card — name, meaning, interpretation.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/birth_chart_copy.dart';
import '../../models/birth_chart.dart';
import '../../models/chart_insight.dart';
import '../../models/life_theme.dart';

class BirthChartPlacementCard extends StatelessWidget {
  const BirthChartPlacementCard({super.key, required this.insight});

  final ChartInsight insight;

  @override
  Widget build(BuildContext context) {
    return OraclyGlassCard(
      padding: OraclyChrome.cardPadding,
      borderRadius: OraclyChrome.cardRadius,
      premium: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.title,
            style: OraclyChrome.sectionLabel(),
          ),
          SizedBox(height: AppSpacing.s8),
          Text(
            insight.body,
            style: ReadingTypography.body(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class BirthChartThemeCard extends StatelessWidget {
  const BirthChartThemeCard({super.key, required this.themes});

  final List<LifeTheme> themes;

  @override
  Widget build(BuildContext context) {
    if (themes.isEmpty) return const SizedBox.shrink();
    return OraclyGlassCard(
      padding: OraclyChrome.cardPadding,
      borderRadius: OraclyChrome.cardRadius,
      premium: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            BirthChartCopy.sectionTheme,
            style: OraclyChrome.sectionLabel(),
          ),
          SizedBox(height: AppSpacing.s8),
          for (final theme in themes) ...[
            Text(theme.title, style: ReadingTypography.sectionLabel()),
            SizedBox(height: AppSpacing.s4),
            Text(
              theme.body,
              style: ReadingTypography.body(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppSpacing.s8),
          ],
        ],
      ),
    );
  }
}

class BirthChartEphemerisNote extends StatelessWidget {
  const BirthChartEphemerisNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      BirthChartCopy.ephemerisNote,
      style: OraclyChrome.bodySecondary(size: 12),
    );
  }
}

List<ChartInsight> birthChartPlacementInsights(BirthChart chart) {
  return chart.insights
      .where(
        (i) =>
            i.kind == ChartInsightKind.bigThree ||
            i.kind == ChartInsightKind.emotionalPatterns ||
            i.kind == ChartInsightKind.strengths,
      )
      .toList();
}
