/// RC-010 — Observable shift or deepening — never predictive.
library;

enum GrowthInsightKind {
  shiftingFocus,
  deepeningTheme,
  newEngagement,
}

class GrowthInsight {
  const GrowthInsight({
    required this.id,
    required this.kind,
    required this.observation,
    required this.observedAt,
    this.evidenceRefs = const [],
  });

  final String id;
  final GrowthInsightKind kind;
  final String observation;
  final DateTime observedAt;
  final List<String> evidenceRefs;
}
