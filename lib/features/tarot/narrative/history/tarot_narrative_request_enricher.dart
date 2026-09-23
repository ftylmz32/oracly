/// Pure Phase 3 → Phase 4 narrative request enrichment boundary (Phase 4D).
library;

import '../evidence/narrative_memory_evidence.dart';
import '../evidence/narrative_request.dart';
import 'tarot_card_recurrence_engine.dart';
import 'tarot_historical_models.dart';
import 'tarot_memory_evidence_engine.dart';
import 'tarot_narrative_enrichment_validation.dart';
import 'tarot_theme_recurrence_engine.dart';

abstract final class TarotNarrativeRequestEnricher {
  TarotNarrativeRequestEnricher._();

  /// Composes card → theme → memory engines. Ignores prior Phase 4 fields on
  /// [base]. When [privacyBlocked], historical engines are not called.
  static TarotNarrativeRequest enrich({
    required TarotNarrativeRequest base,
    required TarotHistoricalSnapshot history,
    required String? currentOwnerId,
    required bool privacyBlocked,
    required DateTime now,
  }) {
    if (privacyBlocked) {
      return TarotNarrativeRequest(
        narrativeTarotVersion: base.narrativeTarotVersion,
        languageCode: base.languageCode,
        sessionId: base.sessionId,
        readingId: base.readingId,
        question: base.question,
        spread: base.spread,
        cards: base.cards,
        relationships: base.relationships,
        memory: const TarotNarrativeMemoryEvidence(
          entries: [],
          priorReadingCount: 0,
          recentCardNames: [],
          recurringThemeLabels: [],
          included: false,
          omitReason: 'privacy',
        ),
        recurringCards: const [],
        recurringThemes: const [],
        bounds: base.bounds,
      );
    }

    final cardResult = TarotCardRecurrenceEngine.build(
      base: base,
      history: history,
      currentOwnerId: currentOwnerId,
      now: now,
    );
    final recurringThemes = TarotThemeRecurrenceEngine.build(
      base: base,
      history: history,
      now: now,
    );
    final memory = TarotMemoryEvidenceEngine.build(
      base: base,
      history: history,
      now: now,
      eligiblePriorReadingCount: cardResult.eligiblePriorReadingCount,
    );

    final enriched = TarotNarrativeRequest(
      narrativeTarotVersion: base.narrativeTarotVersion,
      languageCode: base.languageCode,
      sessionId: base.sessionId,
      readingId: base.readingId,
      question: base.question,
      spread: base.spread,
      cards: base.cards,
      relationships: base.relationships,
      memory: memory,
      recurringCards: List.unmodifiable(cardResult.recurringCards),
      recurringThemes: recurringThemes,
      bounds: base.bounds,
    );
    TarotNarrativeEnrichmentValidation.validate(
      request: enriched,
      history: history,
      currentOwnerId: currentOwnerId,
      now: now,
    );
    return enriched;
  }
}
