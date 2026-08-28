/// Local journal query — never triggers AI.
library;

import 'discovery_journal_kind.dart';
import 'discovery_journal_range.dart';

class DiscoveryJournalQuery {
  const DiscoveryJournalQuery({
    this.range = DiscoveryJournalRange.all,
    this.kind,
    this.savedOnly = false,
    this.theme,
  });

  final DiscoveryJournalRange range;
  final DiscoveryJournalKind? kind;
  final bool savedOnly;
  final String? theme;

  DiscoveryJournalQuery copyWith({
    DiscoveryJournalRange? range,
    DiscoveryJournalKind? kind,
    bool clearKind = false,
    bool? savedOnly,
    String? theme,
    bool clearTheme = false,
  }) {
    return DiscoveryJournalQuery(
      range: range ?? this.range,
      kind: clearKind ? null : (kind ?? this.kind),
      savedOnly: savedOnly ?? this.savedOnly,
      theme: clearTheme ? null : (theme ?? this.theme),
    );
  }
}
