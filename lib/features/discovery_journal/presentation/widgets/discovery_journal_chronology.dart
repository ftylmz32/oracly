/// Chronology chapters from real entry dates — never invented bands.
library;

import '../../copy/discovery_journal_copy.dart';
import '../../models/discovery_journal_entry.dart';

class DiscoveryJournalChapter {
  const DiscoveryJournalChapter({
    required this.label,
    required this.entries,
  });

  final String label;
  final List<DiscoveryJournalEntry> entries;
}

abstract final class DiscoveryJournalChronology {
  DiscoveryJournalChronology._();

  static List<DiscoveryJournalChapter> chapters(
    List<DiscoveryJournalEntry> items, {
    DateTime? now,
  }) {
    if (items.isEmpty) return const [];
    final day = now ?? DateTime.now();
    final recent = <DiscoveryJournalEntry>[];
    final aging = <DiscoveryJournalEntry>[];
    final distant = <DiscoveryJournalEntry>[];
    for (final entry in items) {
      final days = day.difference(entry.date).inDays;
      if (days <= 7) {
        recent.add(entry);
      } else if (days <= 30) {
        aging.add(entry);
      } else {
        distant.add(entry);
      }
    }
    final built = <DiscoveryJournalChapter>[
      if (recent.isNotEmpty)
        DiscoveryJournalChapter(
          label: DiscoveryJournalCopy.recency('recent'),
          entries: recent,
        ),
      if (aging.isNotEmpty)
        DiscoveryJournalChapter(
          label: DiscoveryJournalCopy.recency('aging'),
          entries: aging,
        ),
      if (distant.isNotEmpty)
        DiscoveryJournalChapter(
          label: DiscoveryJournalCopy.recency('distant'),
          entries: distant,
        ),
    ];
    if (built.length == 1) {
      return [
        DiscoveryJournalChapter(label: '', entries: built.first.entries),
      ];
    }
    return built;
  }
}
