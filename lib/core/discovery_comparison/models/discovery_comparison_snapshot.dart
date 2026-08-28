/// One side of a discovery comparison — observational text only.
library;

import '../../l10n/oracly_format.dart';

class DiscoveryComparisonSnapshot {
  const DiscoveryComparisonSnapshot({
    required this.id,
    required this.date,
    required this.title,
    required this.preview,
    required this.text,
  });

  final String id;
  final DateTime date;
  final String title;
  final String preview;
  final String text;

  String get dateLabel => OraclyFormat.date(date);
}
