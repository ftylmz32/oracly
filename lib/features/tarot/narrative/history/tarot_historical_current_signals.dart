/// Shared current-ask signals for Phase 4B theme/memory engines.
library;

import '../evidence/narrative_card_evidence.dart';
import '../evidence/narrative_question_grounding.dart';
import '../evidence/narrative_request.dart';
import 'tarot_historical_text.dart';
import 'tarot_historical_theme_keywords.dart';
import 'tarot_historical_theme_lexicon.dart';

abstract final class TarotHistoricalCurrentSignals {
  TarotHistoricalCurrentSignals._();

  static Set<String> currentCardKeywordIds(
    List<TarotNarrativeCardEvidence> cards,
  ) {
    final out = <String>{};
    for (final c in cards) {
      out.addAll(c.profileSlice.keywordIds);
    }
    return out;
  }

  /// Canonical theme ids from current question topic + raw text.
  static Set<String> currentThemeIds(QuestionGrounding question) {
    final topic = TarotHistoricalText.isMeaningfulTopic(question.topic)
        ? question.topic
        : null;
    return TarotHistoricalThemeLexicon.themeIdsFromText(
      topicId: topic,
      intentionSummary: question.rawText,
    );
  }

  static Set<String> normalizeCanonicalThemes(Iterable<String> raw) {
    final out = <String>{};
    for (final t in raw) {
      final n = TarotHistoricalText.normalizeTopic(t);
      if (n == null) continue;
      if (TarotHistoricalThemeKeywords.byThemeId.containsKey(n)) {
        out.add(n);
      }
    }
    return out;
  }

  static Set<String> queryTokens(QuestionGrounding question) {
    final out = <String>{...TarotHistoricalText.tokens(question.rawText)};
    if (TarotHistoricalText.isMeaningfulTopic(question.topic)) {
      out.addAll(TarotHistoricalText.tokens(question.topic));
    }
    return out;
  }

  static Set<String> cardKeywordsFrom(TarotNarrativeRequest base) =>
      currentCardKeywordIds(base.cards);
}
