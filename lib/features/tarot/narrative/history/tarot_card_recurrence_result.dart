/// Result of pure Tarot card recurrence engine (Phase 4A).
library;

import '../evidence/narrative_recurrence_evidence.dart';

class TarotCardRecurrenceResult {
  TarotCardRecurrenceResult({
    required this.eligiblePriorReadingCount,
    required List<TarotRecurringCardEvidence> recurringCards,
  }) : recurringCards = List<TarotRecurringCardEvidence>.unmodifiable(
         recurringCards,
       );

  final int eligiblePriorReadingCount;
  final List<TarotRecurringCardEvidence> recurringCards;
}
