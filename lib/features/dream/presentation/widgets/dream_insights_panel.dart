/// SPRINT-001 — Reflection, connection, and closing sections.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../widgets/glass_card.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream_insight.dart';
import 'dream_section_header.dart';

class DreamInsightsPanel extends StatelessWidget {
  const DreamInsightsPanel({super.key, required this.insights});

  final List<DreamInsight> insights;

  @override
  Widget build(BuildContext context) {
    final reflections =
        insights.where((i) => i.kind == DreamInsightKind.reflection);
    final possibilities =
        insights.where((i) => i.kind == DreamInsightKind.possibility);
    final connections =
        insights.where((i) => i.kind == DreamInsightKind.personalConnection);
    final question =
        insights.where((i) => i.kind == DreamInsightKind.closingQuestion);
    final takeaway =
        insights.where((i) => i.kind == DreamInsightKind.closingTakeaway);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reflections.isNotEmpty) ...[
          DreamSectionHeader(
            title: DreamCopy.phaseReflection,
            subtitle: DreamCopy.phaseReflectionSubtitle,
          ),
          SizedBox(height: AppSpacing.md),
          for (final insight in reflections)
            _InsightCard(insight: insight, accent: AppColors.purple),
          SizedBox(height: AppSpacing.lg),
        ],
        if (possibilities.isNotEmpty)
          for (final insight in possibilities)
            _InsightCard(insight: insight, accent: AppColors.gold),
        if (connections.isNotEmpty) ...[
          SizedBox(height: AppSpacing.lg),
          DreamSectionHeader(
            title: DreamCopy.phaseConnection,
            subtitle: DreamCopy.phaseConnectionSubtitle,
          ),
          SizedBox(height: AppSpacing.md),
          for (final insight in connections)
            _InsightCard(insight: insight, accent: AppColors.purpleLight),
        ],
        if (question.isNotEmpty || takeaway.isNotEmpty) ...[
          SizedBox(height: AppSpacing.lg),
          DreamSectionHeader(title: DreamCopy.phaseClosing),
          SizedBox(height: AppSpacing.md),
          for (final insight in question)
            _InsightCard(
              insight: insight,
              accent: AppColors.goldLight,
              emphasized: true,
            ),
          for (final insight in takeaway)
            _InsightCard(
              insight: insight,
              accent: AppColors.goldLight,
              style: ReadingTypography.closing(),
            ),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.insight,
    required this.accent,
    this.emphasized = false,
    this.style,
  });

  final DreamInsight insight;
  final Color accent;
  final bool emphasized;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (insight.title != null) ...[
              Text(
                insight.title!,
                style: ReadingTypography.sectionLabel(color: accent),
              ),
              SizedBox(height: AppSpacing.sm),
            ],
            Text(
              insight.body,
              style: style ??
                  (emphasized
                      ? ReadingTypography.bodyCore()
                      : ReadingTypography.reflection()),
            ),
          ],
        ),
      ),
    );
  }
}
