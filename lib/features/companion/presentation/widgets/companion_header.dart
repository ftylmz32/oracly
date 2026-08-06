/// SPRINT-003 — Companion tab header.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';

class CompanionHeader extends StatelessWidget {
  const CompanionHeader({
    super.key,
    required this.subtitle,
    required this.onMemoryTap,
  });

  final String subtitle;
  final VoidCallback onMemoryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenHorizontal.copyWith(
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CompanionCopy.screenTitle,
                  style: ReadingTypography.cardTitle(),
                ),
                Text(subtitle, style: ReadingTypography.opening()),
              ],
            ),
          ),
          TextButton(
            onPressed: onMemoryTap,
            child: Text(
              CompanionCopy.viewMemories,
              style: ReadingTypography.sectionLabel(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
