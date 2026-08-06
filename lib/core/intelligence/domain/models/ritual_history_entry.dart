/// RC-009 — One calendar day of daily ritual engagement.
library;

class RitualHistoryEntry {
  const RitualHistoryEntry({
    required this.date,
    required this.reflectionRead,
    required this.cardDrawn,
    this.personalThought,
  });

  final DateTime date;
  final bool reflectionRead;
  final bool cardDrawn;
  final String? personalThought;

  bool get hasEngagement =>
      reflectionRead ||
      cardDrawn ||
      (personalThought != null && personalThought!.trim().isNotEmpty);
}
