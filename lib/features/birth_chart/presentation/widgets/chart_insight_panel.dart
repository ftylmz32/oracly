/// Placement orbs — only show bodies that were actually calculated.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../widgets/glass_card.dart';
import '../../copy/birth_chart_copy.dart';
import '../../models/birth_chart.dart';
import '../../models/chart_insight.dart';
import '../../services/chart_insight_locale.dart';

class ChartInsightPanel extends StatelessWidget {
  const ChartInsightPanel({
    super.key,
    required this.insight,
    this.chart,
  });

  final ChartInsight insight;
  final BirthChart? chart;

  @override
  Widget build(BuildContext context) {
    final showOrbs = insight.kind == ChartInsightKind.bigThree && chart != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showOrbs) _PlacementOrbs(chart: chart!),
        if (showOrbs) SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight.title, style: ReadingTypography.cardTitle()),
              SizedBox(height: AppSpacing.md),
              Text(
                insight.body,
                style: ReadingTypography.body(color: AppColors.textSecondary),
              ),
              if (insight.glossaryTerm != null &&
                  insight.glossaryExplanation != null) ...[
                SizedBox(height: AppSpacing.lg),
                Text(
                  insight.glossaryTerm!,
                  style: ReadingTypography.sectionLabel(),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  insight.glossaryExplanation!,
                  style: ReadingTypography.footnote(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlacementOrbs extends StatelessWidget {
  const _PlacementOrbs({required this.chart});

  final BirthChart chart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Orb(
            label: BirthChartCopy.sunLabel,
            sign: ChartInsightLocale.signName(chart.sun.sign),
            symbol: chart.sun.sign.symbol,
          ),
        ),
        if (chart.hasFullNatal && chart.moon != null) ...[
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _Orb(
              label: BirthChartCopy.moonLabel,
              sign: ChartInsightLocale.signName(chart.moon!.sign),
              symbol: chart.moon!.sign.symbol,
            ),
          ),
        ],
        if (chart.hasFullNatal && chart.rising != null) ...[
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _Orb(
              label: BirthChartCopy.risingLabel,
              sign: ChartInsightLocale.signName(chart.rising!.sign),
              symbol: chart.rising!.sign.symbol,
            ),
          ),
        ],
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.label,
    required this.sign,
    required this.symbol,
  });

  final String label;
  final String sign;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Text(
            symbol,
            style: TextStyle(
              fontSize: 22,
              color: AppColors.goldLight.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(label, style: ReadingTypography.sectionLabel(fontSize: 10)),
          SizedBox(height: 2),
          Text(
            sign,
            style: ReadingTypography.bodySmall(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
