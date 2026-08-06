/// SPRINT-002 — Big Three celestial display.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../widgets/glass_card.dart';
import '../../copy/birth_chart_copy.dart';
import '../../models/birth_chart.dart';
import '../../models/chart_insight.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (insight.kind == ChartInsightKind.bigThree && chart != null)
          _BigThreeOrbs(chart: chart!),
        if (insight.kind == ChartInsightKind.bigThree && chart != null)
          SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight.title, style: ReadingTypography.cardTitle()),
              SizedBox(height: AppSpacing.md),
              Text(
                insight.body,
                style: ReadingTypography.body(
                  color: AppColors.textSecondary,
                ),
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

class _BigThreeOrbs extends StatelessWidget {
  const _BigThreeOrbs({required this.chart});

  final BirthChart chart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Orb(
            label: BirthChartCopy.sunLabel,
            sign: chart.sun.sign.labelTr,
            symbol: chart.sun.sign.symbol,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Orb(
            label: BirthChartCopy.moonLabel,
            sign: chart.moon.sign.labelTr,
            symbol: chart.moon.sign.symbol,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Orb(
            label: BirthChartCopy.risingLabel,
            sign: chart.rising?.sign.labelTr ?? '—',
            symbol: chart.rising?.sign.symbol ?? '↑',
            muted: chart.rising == null,
          ),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.label,
    required this.sign,
    required this.symbol,
    this.muted = false,
  });

  final String label;
  final String sign;
  final String symbol;
  final bool muted;

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
              color: muted
                  ? AppColors.textHint
                  : AppColors.goldLight.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(label, style: ReadingTypography.sectionLabel(fontSize: 10)),
          SizedBox(height: 2),
          Text(
            sign,
            style: ReadingTypography.bodySmall(
              color: muted ? AppColors.textHint : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
