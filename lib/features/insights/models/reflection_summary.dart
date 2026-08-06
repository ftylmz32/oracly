/// SPRINT-004 — User-facing reflection letter aggregate.
///
/// Distinct from [ReflectionSummary] in `core/reflection` — this model
/// packages insights for the Personal Insights experience.
library;

import 'growth_snapshot.dart';
import 'insight.dart';
import 'personal_pattern.dart';

class InsightReflectionSummary {
  const InsightReflectionSummary({
    required this.salutation,
    required this.generatedAt,
    this.closingNote,
    this.insights = const [],
    this.growthSnapshot,
    this.patterns = const [],
  });

  final String salutation;
  final String? closingNote;
  final List<Insight> insights;
  final GrowthSnapshot? growthSnapshot;
  final List<PersonalPattern> patterns;
  final DateTime generatedAt;

  bool get hasContent =>
      insights.isNotEmpty ||
      growthSnapshot != null ||
      patterns.isNotEmpty;
}
