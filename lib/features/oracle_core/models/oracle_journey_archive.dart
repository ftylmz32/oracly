/// Premium journey archive projection — real observations only.
library;

import 'oracle_theme_history_entry.dart';

class OracleJourneyArchive {
  const OracleJourneyArchive({
    required this.entries,
    required this.generatedAt,
  });

  final List<OracleThemeHistoryEntry> entries;
  final DateTime generatedAt;

  bool get isEmpty => entries.isEmpty;
  bool get isNotEmpty => entries.isNotEmpty;
}
