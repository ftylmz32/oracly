/// SPRINT-004 — Observable pattern across stored activity.
library;

import 'insight_evidence.dart';

class PersonalPattern {
  const PersonalPattern({
    required this.id,
    required this.label,
    required this.observation,
    required this.occurrenceCount,
    this.primarySource = InsightEvidenceSource.tarot,
  });

  final String id;
  final String label;
  final String observation;
  final int occurrenceCount;
  final InsightEvidenceSource primarySource;
}
