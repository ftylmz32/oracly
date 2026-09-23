/// Theme id ↔ NarrativeKeywordIds map (Phase 4 shared lexicon).
library;

import '../domain/narrative_keyword_ids.dart';

abstract final class TarotHistoricalThemeKeywords {
  TarotHistoricalThemeKeywords._();

  static const Map<String, List<String>> byThemeId = {
    'karar': [
      NarrativeKeywordIds.choice,
      NarrativeKeywordIds.direction,
      NarrativeKeywordIds.indecision,
      NarrativeKeywordIds.pause,
    ],
    'ilişki': [
      NarrativeKeywordIds.intimacy,
      NarrativeKeywordIds.union,
      NarrativeKeywordIds.reciprocity,
      NarrativeKeywordIds.attachment,
      NarrativeKeywordIds.belonging,
    ],
    'değişim': [
      NarrativeKeywordIds.change,
      NarrativeKeywordIds.renewal,
      NarrativeKeywordIds.ending,
      NarrativeKeywordIds.opening,
    ],
    'sınır': [
      NarrativeKeywordIds.boundary,
      NarrativeKeywordIds.closing,
      NarrativeKeywordIds.resistance,
    ],
    'kariyer': [
      NarrativeKeywordIds.craft,
      NarrativeKeywordIds.discipline,
      NarrativeKeywordIds.direction,
      NarrativeKeywordIds.externalDemand,
    ],
    'iletişim': [
      NarrativeKeywordIds.communication,
      NarrativeKeywordIds.harshSpeech,
      NarrativeKeywordIds.truth,
    ],
    'belirsizlik': [
      NarrativeKeywordIds.confusion,
      NarrativeKeywordIds.doubt,
      NarrativeKeywordIds.indecision,
    ],
    'özgüven': [
      NarrativeKeywordIds.courage,
      NarrativeKeywordIds.agency,
      NarrativeKeywordIds.boast,
    ],
  };
}
