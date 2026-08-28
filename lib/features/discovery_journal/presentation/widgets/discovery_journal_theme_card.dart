/// One real recurring theme — readable summary first, quiet evidence second.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../personal_discovery/models/cross_discovery_insight.dart';
import '../../copy/discovery_journal_copy.dart';
import '../../models/discovery_journal_kind.dart';
import 'discovery_journal_entry_icon.dart';

class DiscoveryJournalThemeCard extends StatelessWidget {
  const DiscoveryJournalThemeCard({
    super.key,
    required this.insight,
    this.focused = false,
  });

  final CrossDiscoveryInsight insight;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final summary = DiscoveryJournalCopy.insight(insight);
    final kinds = insight.sources
        .map(DiscoveryJournalEntryIcon.fromSource)
        .whereType<DiscoveryJournalKind>()
        .toList();
    final evidence = DiscoveryJournalCopy.sourcesLine(insight.sources);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DiscoveryJournalCopy.heroTheme(insight.theme),
          style: ReadingTypography.sectionLabel(
            color: OraclyChrome.goldLight.withValues(
              alpha: focused ? 1 : 0.92,
            ),
            fontSize: 13,
          ),
        ),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            summary,
            style: ReadingTypography.body(
              color: OraclyChrome.cream.withValues(alpha: 0.78),
            ),
          ),
        ],
        if (evidence.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            evidence,
            style: ReadingTypography.footnote(
              color: OraclyChrome.cream.withValues(alpha: 0.58),
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: focused
          ? DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: OraclyChrome.gold.withValues(alpha: 0.72),
                    width: 2,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.s8),
                child: body,
              ),
            )
          : body,
    );
  }
}
