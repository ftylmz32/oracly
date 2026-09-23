/// Deterministic contextsOverlap for historical card recurrence (Phase 4A).
library;

import '../evidence/narrative_card_evidence.dart';
import '../evidence/narrative_question_grounding.dart';
import 'tarot_historical_models.dart';
import 'tarot_historical_text.dart';
import 'tarot_historical_theme_lexicon.dart';

class TarotRecurrenceContextMatch {
  const TarotRecurrenceContextMatch({required this.overlaps, this.summaryKey});

  final bool overlaps;
  final String? summaryKey;
}

abstract final class TarotRecurrenceContext {
  TarotRecurrenceContext._();

  static const topicMatch = 'topic_match';
  static const kindToken = 'kind_token';
  static const keywordMap = 'keyword_map';

  static const _kindTokenKinds = {
    QuestionKind.relationship,
    QuestionKind.decision,
  };

  /// Precedence: topic_match > kind_token > keyword_map.
  static TarotRecurrenceContextMatch evaluate({
    required QuestionGrounding currentQuestion,
    required List<TarotNarrativeCardEvidence> currentCards,
    required TarotHistoricalReadingRecord historical,
    required TarotHistoricalCardOccurrence matchedOccurrence,
  }) {
    // matchedOccurrence reserved for future position-scoped rules; unused.
    // ignore: unused_local_variable
    final _ = matchedOccurrence;

    if (_topicExact(currentQuestion.topic, historical.topicId)) {
      return const TarotRecurrenceContextMatch(
        overlaps: true,
        summaryKey: topicMatch,
      );
    }
    if (_kindToken(currentQuestion, historical)) {
      return const TarotRecurrenceContextMatch(
        overlaps: true,
        summaryKey: kindToken,
      );
    }
    if (_keywordMap(currentCards, historical)) {
      return const TarotRecurrenceContextMatch(
        overlaps: true,
        summaryKey: keywordMap,
      );
    }
    return const TarotRecurrenceContextMatch(overlaps: false);
  }

  /// Strongest of [keys]: topic_match > kind_token > keyword_map.
  static String? strongestKey(Iterable<String?> keys) {
    var best = -1;
    String? out;
    for (final k in keys) {
      final rank = _rank(k);
      if (rank > best) {
        best = rank;
        out = k;
      }
    }
    return out;
  }

  static int _rank(String? key) => switch (key) {
    topicMatch => 3,
    kindToken => 2,
    keywordMap => 1,
    _ => 0,
  };

  static bool _topicExact(String? currentTopic, String? historicalTopicId) {
    final a = TarotHistoricalText.normalizeTopic(currentTopic);
    final b = TarotHistoricalText.normalizeTopic(historicalTopicId);
    if (a == null || b == null) return false;
    return a == b;
  }

  static bool _kindToken(
    QuestionGrounding current,
    TarotHistoricalReadingRecord historical,
  ) {
    if (current.kind != historical.questionKind) return false;
    if (!_kindTokenKinds.contains(current.kind)) return false;
    final cur = TarotHistoricalText.tokens(current.rawText);
    final hist = TarotHistoricalText.tokens(historical.intentionSummary);
    return cur.intersection(hist).isNotEmpty;
  }

  static bool _keywordMap(
    List<TarotNarrativeCardEvidence> currentCards,
    TarotHistoricalReadingRecord historical,
  ) {
    final currentKw = <String>{};
    for (final c in currentCards) {
      currentKw.addAll(c.profileSlice.keywordIds);
    }
    if (currentKw.isEmpty) return false;
    final themes = TarotHistoricalThemeLexicon.themeIdsFromText(
      topicId: historical.topicId,
      intentionSummary: historical.intentionSummary,
    );
    final histKw = TarotHistoricalThemeLexicon.keywordIdsForThemes(themes);
    return currentKw.intersection(histKw).isNotEmpty;
  }
}
