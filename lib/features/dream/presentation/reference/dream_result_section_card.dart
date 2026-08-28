/// Dream section surfaces — differentiated hierarchy per insight kind.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../models/dream_insight.dart';
import '../../services/dream_reading_presentation.dart';
import 'dream_result_section_body.dart';

class DreamResultSectionCard extends StatelessWidget {
  const DreamResultSectionCard({super.key, required this.section});

  final DreamReadingSection section;

  @override
  Widget build(BuildContext context) {
    return switch (section.kind) {
      DreamInsightKind.summary => const SizedBox.shrink(),
      DreamInsightKind.symbols => DreamSymbolsSection(section: section),
      DreamInsightKind.emotionalMeaning => DreamDeepSection(section: section),
      DreamInsightKind.mainInterpretation => DreamEditorialSection(section: section),
      DreamInsightKind.personalConnection => DreamEditorialSection(section: section),
      DreamInsightKind.themes => DreamAccentSection(section: section),
      DreamInsightKind.closingTakeaway => DreamClosingSection(section: section),
      _ => DreamEditorialSection(section: section),
    };
  }
}

class DreamSymbolsSection extends StatelessWidget {
  const DreamSymbolsSection({super.key, required this.section});

  final DreamReadingSection section;

  @override
  Widget build(BuildContext context) {
    final parts = section.body
        .split(RegExp(r'[\n·,;]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(8)
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DreamSectionLabel(title: section.title),
          SizedBox(height: AppSpacing.sm),
          if (parts.length >= 2)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final part in parts)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: OraclyChrome.cardSurface.withValues(alpha: 0.10),
                      border: Border.all(
                        color: OraclyChrome.gold.withValues(alpha: 0.14),
                        width: 0.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        part,
                        style: ReadingTypography.bodySmall(
                          color: OraclyChrome.cream.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            Text(
              section.body,
              style: ReadingTypography.body(
                color: OraclyChrome.cream.withValues(alpha: 0.90),
              ),
            ),
        ],
      ),
    );
  }
}

class DreamClosingSection extends StatelessWidget {
  const DreamClosingSection({super.key, required this.section});

  final DreamReadingSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: OraclyChrome.violet.withValues(alpha: 0.06),
          border: Border(
            left: BorderSide(
              color: OraclyChrome.gold.withValues(alpha: 0.24),
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DreamSectionLabel(title: section.title, gold: 0.76),
              SizedBox(height: AppSpacing.sm),
              Text(
                section.body,
                style: ReadingTypography.closing(
                  color: OraclyChrome.cream.withValues(alpha: 0.86),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
