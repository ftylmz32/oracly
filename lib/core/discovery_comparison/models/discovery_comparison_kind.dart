/// Comparable discovery kinds — only where pairing is meaningful.
library;

import '../../../features/discovery_journal/models/discovery_journal_kind.dart';

enum DiscoveryComparisonKind {
  tarot,
  dailyMessage,
  starMap,
  astrology,
  companion;

  static DiscoveryComparisonKind? fromJournalKind(DiscoveryJournalKind kind) =>
      switch (kind) {
        DiscoveryJournalKind.tarot => tarot,
        DiscoveryJournalKind.dailyMessage => dailyMessage,
        DiscoveryJournalKind.starMap => starMap,
        DiscoveryJournalKind.astrology => astrology,
        DiscoveryJournalKind.companion => companion,
        _ => null,
      };
}
