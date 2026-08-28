/// Timeline chrome fragments — recommendation, filters, empty, footer.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/discovery_journal_copy.dart';
import '../../models/discovery_journal_filter_options.dart';
import '../../models/discovery_journal_query.dart';
import 'discovery_journal_filters.dart';
import 'discovery_recommendation_card.dart';

abstract final class DiscoveryJournalTimelineChrome {
  DiscoveryJournalTimelineChrome._();

  static const recommendation = Padding(
    padding: EdgeInsets.only(bottom: AppSpacing.s12),
    child: DiscoveryRecommendationCard(),
  );

  static Widget filters({
    required DiscoveryJournalQuery query,
    required DiscoveryJournalFilterOptions options,
    required ValueChanged<DiscoveryJournalQuery> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: DiscoveryJournalFilters(
        query: query,
        options: options,
        onChanged: onChanged,
      ),
    );
  }

  static Widget get footer => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s8),
        child: Text(
          DiscoveryJournalCopy.soulMateNote,
          style: ReadingTypography.footnote(
            color: OraclyChrome.cream.withValues(alpha: 0.42),
          ),
        ),
      );

  static Widget get empty => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s8),
        child: Text(
          DiscoveryJournalCopy.filterEmpty,
          style: ReadingTypography.body(
            color: OraclyChrome.cream.withValues(alpha: 0.72),
          ),
        ),
      );
}
