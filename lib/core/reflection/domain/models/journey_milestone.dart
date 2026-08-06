/// RC-010 — Factual journey markers derived from stored history.
library;

enum JourneyMilestoneKind {
  firstReading,
  readingCount,
  firstReflection,
  firstFavorite,
  recurringCard,
  firstRitualThought,
}

class JourneyMilestone {
  const JourneyMilestone({
    required this.id,
    required this.kind,
    required this.reachedAt,
    required this.label,
    this.detail,
  });

  final String id;
  final JourneyMilestoneKind kind;
  final DateTime reachedAt;
  final String label;
  final String? detail;
}
