/// OR-1140 — Compatibility engine input payload.
library;

class CompatibilityEngineInput {
  const CompatibilityEngineInput({
    required this.subjectA,
    required this.subjectB,
    this.chartA,
    this.chartB,
  });

  final String subjectA;
  final String subjectB;
  final Map<String, dynamic>? chartA;
  final Map<String, dynamic>? chartB;
}
