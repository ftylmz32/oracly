/// RC-011 — Journey and ritual coordination context.
library;

class JourneyContext {
  const JourneyContext({
    required this.hasJourneyMemory,
    required this.highlightTodaysRitual,
    required this.ritualCompletedToday,
    required this.totalReadings,
    required this.hasRecurringPatterns,
  });

  final bool hasJourneyMemory;
  final bool highlightTodaysRitual;
  final bool ritualCompletedToday;
  final int totalReadings;
  final bool hasRecurringPatterns;
}
