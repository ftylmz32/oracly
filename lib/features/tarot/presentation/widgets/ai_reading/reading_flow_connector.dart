/// TASK-001 — Quiet bridges between reading acts.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';
import 'reading_sacred_rhythm.dart';

/// A whisper divider — connects sections without breaking calm.
class ReadingFlowConnector extends StatelessWidget {
  const ReadingFlowConnector({
    super.key,
    this.label,
    this.compact = false,
  });

  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final top = compact
        ? ReadingSacredRhythm.betweenSections * 0.6
        : ReadingSacredRhythm.betweenActs;
    final bottom = compact ? AppSpacing.sm : AppSpacing.md;

    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: Column(
        children: [
          Center(
            child: Container(
              width: compact ? 28 : 44,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.transparent,
                    AppColors.gold.withValues(alpha: compact ? 0.14 : 0.20),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),
          if (label != null && label!.trim().isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              label!,
              textAlign: TextAlign.center,
              style: ReadingTypography.sectionLabel(
                fontSize: 10,
                color: AppColors.textHint.withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
