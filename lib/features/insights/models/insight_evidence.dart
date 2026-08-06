/// SPRINT-004 — Traceable evidence backing an insight.
library;

enum InsightEvidenceSource {
  tarot,
  dream,
  birthChart,
  journal,
  companion,
  favoriteCard,
  savedReflection,
}

class InsightEvidence {
  const InsightEvidence({
    required this.source,
    required this.reference,
    this.observedAt,
  });

  final InsightEvidenceSource source;
  final String reference;
  final DateTime? observedAt;
}
