/// Pure memory relevance scoring (Phase 4B).
library;

import '../evidence/narrative_question_grounding.dart';
import 'tarot_connected_memory_models.dart';
import 'tarot_historical_current_signals.dart';
import 'tarot_historical_recall.dart';
import 'tarot_historical_text.dart';
import 'tarot_historical_theme_lexicon.dart';

abstract final class TarotMemoryRelevance {
  TarotMemoryRelevance._();

  /// Max applicable signal in [0,1]. Below 0.35 → not relevant.
  static double score({
    required TarotConnectedMemoryRecord record,
    required QuestionGrounding question,
    required Set<String> currentThemes,
    required Set<String> currentCardKeywords,
  }) {
    var score = 0.0;
    final recordThemes = TarotHistoricalCurrentSignals.normalizeCanonicalThemes(
      record.themeIds,
    );

    if (recordThemes.intersection(currentThemes).isNotEmpty) {
      score = 0.80;
    }

    if (question.hasRealQuestion) {
      final query = TarotHistoricalCurrentSignals.queryTokens(question);
      final summary = TarotHistoricalText.tokens(record.summary);
      if (query.intersection(summary).length >= 2) {
        if (score < 0.70) score = 0.70;
      }
    }

    final themeKw = TarotHistoricalThemeLexicon.keywordIdsForThemes(
      recordThemes,
    );
    if (currentCardKeywords.intersection(themeKw).isNotEmpty) {
      if (score < 0.55) score = 0.55;
    }

    if (TarotHistoricalRecall.detects(question.rawText)) {
      if (score < 0.50) score = 0.50;
    }

    return score > 1.0 ? 1.0 : score;
  }
}
