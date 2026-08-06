/// SPRINT-004 — A single compassionate personal insight.
library;

import 'insight_category.dart';
import 'insight_evidence.dart';

class Insight {
  const Insight({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.generatedAt,
    this.evidence = const [],
  });

  final String id;
  final InsightCategory category;
  final String title;
  final String body;
  final DateTime generatedAt;
  final List<InsightEvidence> evidence;
}
