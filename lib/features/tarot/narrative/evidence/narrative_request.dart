/// Closed request bounds + TarotNarrativeRequest model (Phase 3D.1A).
library;

import 'narrative_card_evidence.dart';
import 'narrative_memory_evidence.dart';
import 'narrative_question_grounding.dart';
import 'narrative_recurrence_evidence.dart';
import 'narrative_relationship_evidence.dart';
import 'narrative_spread_semantics.dart';

class RequestBounds {
  const RequestBounds({
    required this.maxPriorReadingsScanned,
    required this.maxRecurringOccurrencesListed,
    required this.maxRelationships,
    required this.maxMemoryChars,
    required this.maxThemeLabels,
  });

  final int maxPriorReadingsScanned;
  final int maxRecurringOccurrencesListed;
  final int maxRelationships;
  final int maxMemoryChars;
  final int maxThemeLabels;

  /// Canonical Phase 3D.1 defaults. 90-day lookback is Phase 4 provider policy.
  static const defaults = RequestBounds(
    maxPriorReadingsScanned: 20,
    maxRecurringOccurrencesListed: 5,
    maxRelationships: 12,
    maxMemoryChars: 800,
    maxThemeLabels: 4,
  );
}

class TarotNarrativeRequest {
  const TarotNarrativeRequest({
    required this.narrativeTarotVersion,
    required this.languageCode,
    required this.sessionId,
    required this.readingId,
    required this.question,
    required this.spread,
    required this.cards,
    required this.relationships,
    required this.memory,
    required this.recurringCards,
    required this.recurringThemes,
    required this.bounds,
  });

  static const currentNarrativeVersion = 2;

  final int narrativeTarotVersion;
  final String languageCode;
  final String sessionId;
  final String readingId;
  final QuestionGrounding question;
  final SpreadSemanticDefinition spread;
  final List<TarotNarrativeCardEvidence> cards;
  final List<TarotNarrativeRelationshipEvidence> relationships;
  final TarotNarrativeMemoryEvidence memory;
  final List<TarotRecurringCardEvidence> recurringCards;
  final List<TarotRecurringThemeEvidence> recurringThemes;
  final RequestBounds bounds;
}
