/// Dream section body widgets — split to keep files under 150 lines.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../services/dream_reading_presentation.dart';

class DreamSectionLabel extends StatelessWidget {
  const DreamSectionLabel({super.key, required this.title, this.gold = 0.72});

  final String title;
  final double gold;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: ReadingTypography.sectionLabel(
        color: OraclyChrome.goldLight.withValues(alpha: gold),
      ),
    );
  }
}

class DreamEditorialSection extends StatelessWidget {
  const DreamEditorialSection({super.key, required this.section});

  final DreamReadingSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DreamSectionLabel(title: section.title),
          SizedBox(height: AppSpacing.sm),
          Text(
            section.body,
            style: ReadingTypography.body(
              color: OraclyChrome.cream.withValues(alpha: 0.92),
            ).copyWith(height: CraftsmanshipRhythm.bodyLineHeight),
          ),
        ],
      ),
    );
  }
}

class DreamDeepSection extends StatelessWidget {
  const DreamDeepSection({super.key, required this.section});

  final DreamReadingSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.s16,
          color: const Color(0xFF100E16).withValues(alpha: 0.72),
          border: Border.all(
            color: OraclyChrome.violet.withValues(alpha: 0.16),
            width: 0.6,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DreamSectionLabel(title: section.title, gold: 0.68),
              SizedBox(height: AppSpacing.sm),
              Text(
                section.body,
                style: ReadingTypography.reflection(
                  color: OraclyChrome.cream.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DreamAccentSection extends StatelessWidget {
  const DreamAccentSection({super.key, required this.section});

  final DreamReadingSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.s16,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              OraclyChrome.gold.withValues(alpha: 0.08),
              const Color(0xFF120E18).withValues(alpha: 0.86),
            ],
          ),
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: 0.36),
            width: 0.8,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DreamSectionLabel(title: section.title, gold: 0.92),
              SizedBox(height: AppSpacing.sm),
              Text(
                section.body,
                style: ReadingTypography.body(
                  color: OraclyChrome.cream.withValues(alpha: 0.94),
                ).copyWith(height: CraftsmanshipRhythm.bodyLineHeight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
