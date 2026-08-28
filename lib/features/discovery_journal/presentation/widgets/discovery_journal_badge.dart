/// Compact type badge for a journal row.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/discovery_journal_copy.dart';
import '../../models/discovery_journal_kind.dart';

class DiscoveryJournalBadge extends StatelessWidget {
  const DiscoveryJournalBadge({super.key, required this.kind});

  final DiscoveryJournalKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.s8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
      ),
      child: Text(
        DiscoveryJournalCopy.badge(kind),
        style: ReadingTypography.sectionLabel(
          color: AppColors.goldLight,
          fontSize: 10,
        ),
      ),
    );
  }
}
