/// EPIC-011 — Daily ritual state for one calendar day.
library;

/// Gentle engagement markers — no streaks, no scores.
class DailyRitualDay {
  const DailyRitualDay({
    this.reflectionRead = false,
    this.cardDrawn = false,
    this.personalThought,
  });

  final bool reflectionRead;
  final bool cardDrawn;
  final String? personalThought;

  bool get hasEngaged =>
      reflectionRead ||
      cardDrawn ||
      (personalThought != null && personalThought!.trim().isNotEmpty);

  DailyRitualDay copyWith({
    bool? reflectionRead,
    bool? cardDrawn,
    String? personalThought,
    bool clearThought = false,
  }) {
    return DailyRitualDay(
      reflectionRead: reflectionRead ?? this.reflectionRead,
      cardDrawn: cardDrawn ?? this.cardDrawn,
      personalThought:
          clearThought ? null : (personalThought ?? this.personalThought),
    );
  }
}
