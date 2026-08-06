/// SPRINT-004 — Gentle snapshot of observable growth over time.
library;

import 'insight.dart';

class GrowthSnapshot {
  const GrowthSnapshot({
    required this.narrative,
    required this.asOf,
    this.highlights = const [],
  });

  final String narrative;
  final DateTime asOf;
  final List<Insight> highlights;
}
