/// RC-010 — Theme that recurs across sessions — observation only.
library;

import 'reflection_evidence_kind.dart';

class RecurringTheme {
  const RecurringTheme({
    required this.id,
    required this.label,
    required this.occurrenceCount,
    required this.firstObserved,
    required this.lastObserved,
    this.evidence = ReflectionEvidenceKind.themeTag,
  });

  final String id;
  final String label;
  final int occurrenceCount;
  final DateTime firstObserved;
  final DateTime lastObserved;
  final ReflectionEvidenceKind evidence;
}
