/// One timeline row from an existing persisted record.
library;

import '../../../core/l10n/oracly_format.dart';
import 'discovery_journal_kind.dart';

class DiscoveryJournalEntry {
  const DiscoveryJournalEntry({
    required this.id,
    required this.kind,
    required this.date,
    required this.title,
    this.preview = '',
    this.themes = const [],
    this.isSaved = false,
  });

  final String id;
  final DiscoveryJournalKind kind;
  final DateTime date;
  final String title;
  final String preview;
  final List<String> themes;
  final bool isSaved;

  DiscoveryJournalEntry copyWith({
    List<String>? themes,
    bool? isSaved,
  }) {
    return DiscoveryJournalEntry(
      id: id,
      kind: kind,
      date: date,
      title: title,
      preview: preview,
      themes: themes ?? this.themes,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  String get dateLabel => OraclyFormat.dayMonth(date);
}
