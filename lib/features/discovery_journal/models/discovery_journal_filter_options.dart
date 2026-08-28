/// Only filters backed by real rows — never decorative empty chips.
library;

import 'discovery_journal_kind.dart';
import 'discovery_journal_range.dart';

class DiscoveryJournalFilterOptions {
  const DiscoveryJournalFilterOptions({
    this.ranges = const [DiscoveryJournalRange.all],
    this.kinds = const [],
    this.themes = const [],
    this.hasSaved = false,
  });

  final List<DiscoveryJournalRange> ranges;
  final List<DiscoveryJournalKind> kinds;
  final List<String> themes;
  final bool hasSaved;

  bool get hasAdvanced =>
      kinds.isNotEmpty || themes.isNotEmpty || hasSaved || ranges.length > 1;
}
