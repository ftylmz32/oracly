/// Keeps active query aligned with chips that real data supports.
library;

import '../models/discovery_journal_filter_options.dart';
import '../models/discovery_journal_query.dart';
import '../models/discovery_journal_range.dart';

abstract final class DiscoveryJournalQuerySanitize {
  DiscoveryJournalQuerySanitize._();

  static DiscoveryJournalQuery of(
    DiscoveryJournalQuery query,
    DiscoveryJournalFilterOptions options,
  ) {
    final range = options.ranges.contains(query.range)
        ? query.range
        : DiscoveryJournalRange.all;
    final kind = query.kind != null && options.kinds.contains(query.kind)
        ? query.kind
        : null;
    final theme = query.theme;
    String? matchedTheme;
    if (theme != null) {
      for (final candidate in options.themes) {
        if (candidate.toLowerCase() == theme.toLowerCase()) {
          matchedTheme = candidate;
          break;
        }
      }
    }
    return DiscoveryJournalQuery(
      range: range,
      kind: kind,
      savedOnly: query.savedOnly && options.hasSaved,
      theme: matchedTheme,
    );
  }
}
