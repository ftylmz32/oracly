/// Theme relevance + related-card helpers (Phase 4B).
library;

import '../evidence/narrative_card_evidence.dart';
import '../evidence/narrative_question_grounding.dart';
import 'tarot_connected_memory_models.dart';
import 'tarot_historical_theme_keywords.dart';
import 'tarot_historical_theme_lexicon.dart';

abstract final class TarotThemeRecurrenceSupport {
  TarotThemeRecurrenceSupport._();

  static double relevance({
    required String themeId,
    required QuestionGrounding question,
    required Set<String> currentThemes,
    required Set<String> currentKw,
    required bool recall,
  }) {
    var score = 0.0;
    final themeKw = TarotHistoricalThemeLexicon.keywordIdsForThemes([themeId]);
    if (currentKw.intersection(themeKw).isNotEmpty) score = 0.55;
    if (currentThemes.contains(themeId) && score < 0.70) score = 0.70;
    if (question.kind == QuestionKind.relationship &&
        themeId == 'ilişki' &&
        score < 0.80) {
      score = 0.80;
    }
    if (question.kind == QuestionKind.decision &&
        themeId == 'karar' &&
        score < 0.80) {
      score = 0.80;
    }
    if (recall && score < 0.50) score = 0.50;
    return score > 1.0 ? 1.0 : score;
  }

  static List<String> supportRefs(
    List<TarotConnectedMemoryRecord> supports,
    int maxListed,
  ) {
    final sorted = List<TarotConnectedMemoryRecord>.from(supports)
      ..sort((a, b) {
        final byTime = b.occurredAt.toUtc().compareTo(a.occurredAt.toUtc());
        if (byTime != 0) return byTime;
        final byType = a.sourceType.name.compareTo(b.sourceType.name);
        if (byType != 0) return byType;
        return a.sourceId.compareTo(b.sourceId);
      });
    final cap = maxListed < 0 ? 0 : maxListed;
    final refs = <String>[for (final s in sorted.take(cap)) s.typedSourceRef];
    return List<String>.unmodifiable(refs);
  }

  static List<String> relatedCards(
    String themeId,
    List<TarotNarrativeCardEvidence> cards,
  ) {
    final themeSet =
        (TarotHistoricalThemeKeywords.byThemeId[themeId] ?? const []).toSet();
    final hits =
        [
          for (final c in cards)
            if (c.profileSlice.keywordIds
                .toSet()
                .intersection(themeSet)
                .isNotEmpty)
              c,
        ]..sort((a, b) {
          final byPos = a.positionIndex.compareTo(b.positionIndex);
          if (byPos != 0) return byPos;
          return a.canonicalCardId.compareTo(b.canonicalCardId);
        });
    return List<String>.unmodifiable(
      hits.map((c) => c.canonicalCardId).toList(),
    );
  }
}
