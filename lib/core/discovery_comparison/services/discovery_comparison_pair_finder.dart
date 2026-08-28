/// Finds the prior journal row for a same-kind comparison.
library;

import '../../../features/discovery_journal/models/discovery_journal_entry.dart';
import '../models/discovery_comparison_kind.dart';

abstract final class DiscoveryComparisonPairFinder {
  DiscoveryComparisonPairFinder._();

  static DiscoveryJournalEntry? priorEntry(
    List<DiscoveryJournalEntry> items,
    DiscoveryJournalEntry current,
  ) {
    if (DiscoveryComparisonKind.fromJournalKind(current.kind) == null) {
      return null;
    }
    DiscoveryJournalEntry? prior;
    for (final item in items) {
      if (item.kind != current.kind || item.id == current.id) continue;
      if (!item.date.isBefore(current.date)) continue;
      if (prior == null || item.date.isAfter(prior.date)) prior = item;
    }
    return prior;
  }
}
