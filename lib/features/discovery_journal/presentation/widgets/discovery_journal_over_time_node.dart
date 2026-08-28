/// One theme node on the over-time editorial spine.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../personal_discovery/models/theme_over_time_comparison.dart';
import '../../copy/discovery_journal_copy.dart';
import '../../copy/discovery_journal_over_time_copy.dart';
import '../../models/discovery_journal_kind.dart';
import 'discovery_journal_entry_icon.dart';

class DiscoveryJournalOverTimeNode extends StatelessWidget {
  const DiscoveryJournalOverTimeNode({
    super.key,
    required this.label,
    required this.window,
  });

  final String label;
  final ThemeOverTimeWindow window;

  @override
  Widget build(BuildContext context) {
    final kinds = window.sources
        .map(DiscoveryJournalEntryIcon.fromSource)
        .whereType<DiscoveryJournalKind>()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ReadingTypography.footnote(
            color: OraclyChrome.cream.withValues(alpha: 0.52),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          DiscoveryJournalOverTimeCopy.themeLabel(window.theme),
          style: ReadingTypography.sectionLabel(
            color: OraclyChrome.goldLight,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          DiscoveryJournalCopy.discoveries(window.sightingCount),
          style: ReadingTypography.footnote(
            color: OraclyChrome.cream.withValues(alpha: 0.58),
          ),
        ),
        if (kinds.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              for (final kind in kinds)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    DiscoveryJournalEntryIcon.of(kind),
                    size: 14,
                    color: OraclyChrome.gold.withValues(alpha: 0.72),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
