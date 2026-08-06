/// RC-010 — Observable movement between time periods.
library;

enum PersonalTrendKind {
  themeFocus,
  cardRecurrence,
  reflectionCadence,
  spreadPreference,
}

enum TrendDirection {
  rising,
  steady,
  fading,
}

class PersonalTrend {
  const PersonalTrend({
    required this.id,
    required this.kind,
    required this.subject,
    required this.direction,
    required this.recentPeriodCount,
    required this.priorPeriodCount,
    required this.recentPeriodLabel,
    required this.priorPeriodLabel,
  });

  final String id;
  final PersonalTrendKind kind;
  final String subject;
  final TrendDirection direction;
  final int recentPeriodCount;
  final int priorPeriodCount;
  final String recentPeriodLabel;
  final String priorPeriodLabel;
}
