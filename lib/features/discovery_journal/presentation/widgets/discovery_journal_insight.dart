/// Observational cross-insight plus ORACLY's non-predictive philosophy.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../personal_discovery/models/cross_discovery_insight.dart';
import '../../copy/discovery_journal_copy.dart';

class DiscoveryJournalInsight extends StatelessWidget {
  const DiscoveryJournalInsight({super.key, this.insight});

  final CrossDiscoveryInsight? insight;

  @override
  Widget build(BuildContext context) {
    final line = insight == null ? '' : DiscoveryJournalCopy.insight(insight!);
    if (line.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: Text(
        line,
        style: ReadingTypography.body(
          color: OraclyChrome.cream.withValues(alpha: 0.88),
        ),
      ),
    );
  }
}
