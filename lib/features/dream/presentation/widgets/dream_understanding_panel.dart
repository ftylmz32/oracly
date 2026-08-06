/// SPRINT-001 — Phase 2 understanding panel (no interpretation).
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../widgets/glass_card.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream.dart';
import 'dream_section_header.dart';

class DreamUnderstandingPanel extends StatelessWidget {
  const DreamUnderstandingPanel({super.key, required this.understanding});

  final DreamUnderstanding understanding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DreamSectionHeader(
          title: DreamCopy.phaseUnderstanding,
          subtitle: DreamCopy.phaseUnderstandingSubtitle,
        ),
        SizedBox(height: AppSpacing.md),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(understanding.summary, style: ReadingTypography.bodyCore()),
              SizedBox(height: AppSpacing.lg),
              _Section(
                title: DreamCopy.symbolsTitle,
                items: understanding.symbols.map((s) => s.label).toList(),
                empty: DreamCopy.noSymbols,
              ),
              _Section(
                title: DreamCopy.emotionsTitle,
                items: understanding.emotions,
                empty: '—',
              ),
              _Section(
                title: DreamCopy.locationsTitle,
                items: understanding.locations,
                empty: DreamCopy.noLocations,
              ),
              _Section(
                title: DreamCopy.relationshipsTitle,
                items: understanding.relationships.map((r) => r.label).toList(),
                empty: DreamCopy.noRelationships,
              ),
              _Section(
                title: DreamCopy.recurringTitle,
                items: understanding.recurringElements,
                empty: DreamCopy.noRecurring,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.empty,
  });

  final String title;
  final List<String> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ReadingTypography.sectionLabel()),
          SizedBox(height: AppSpacing.xs),
          if (items.isEmpty)
            Text(empty, style: ReadingTypography.bodySmall())
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final item in items)
                  DreamChip(label: item, selected: true),
              ],
            ),
        ],
      ),
    );
  }
}
