import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_01.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_06.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_text.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_recurrence_context.dart';

import 'tarot_history_test_support.dart';

void main() {
  group('TarotHistoricalText', () {
    test('topic normalize TR İ / whitespace', () {
      expect(
        TarotHistoricalText.normalizeTopic(' İlişki '),
        TarotHistoricalText.normalizeTopic('ilişki'),
      );
      expect(
        TarotHistoricalText.normalizeTopic('relationship'),
        isNot(TarotHistoricalText.normalizeTopic('ilişki')),
      );
    });

    test('stopwords TR/EN/RU excluded; short tokens dropped', () {
      expect(TarotHistoricalText.tokens('bir daha sonra'), isEmpty);
      expect(TarotHistoricalText.tokens('this that with from'), isEmpty);
      expect(TarotHistoricalText.tokens('этот когда сейчас'), isEmpty);
      expect(
        TarotHistoricalText.tokens('partner loyalty'),
        contains('partner'),
      );
      expect(
        TarotHistoricalText.tokens('partner loyalty'),
        contains('loyalty'),
      );
    });
  });

  group('TarotRecurrenceContext', () {
    const occ = TarotHistoricalCardOccurrence(
      canonicalCardId: 'major_00',
      isReversed: false,
      positionKey: 'sign',
      positionIndex: 0,
    );

    test('topic exact → topic_match', () {
      final q = NarrativeQuestionGrounding.from(
        rawQuestion: 'anything here long',
        topic: ' İlişki ',
      );
      final hist = histReading(
        readingId: 'h1',
        at: nowFixed.subtract(const Duration(days: 1)),
        topicId: 'ilişki',
        cardId: major00,
      );
      final m = TarotRecurrenceContext.evaluate(
        currentQuestion: q,
        currentCards: [cardEvidence(kNarrativeMajor06, positionIndex: 0)],
        historical: hist,
        matchedOccurrence: occ,
      );
      expect(m.overlaps, isTrue);
      expect(m.summaryKey, TarotRecurrenceContext.topicMatch);
    });

    test('kind_token relationship/decision only', () {
      final hist = histReading(
        readingId: 'h1',
        at: nowFixed.subtract(const Duration(days: 1)),
        questionKind: QuestionKind.relationship,
        intentionSummary: 'loyalty partner future',
        cardId: major00,
      );
      final rel = QuestionGrounding(
        rawText: 'loyalty partner worries',
        topic: null,
        kind: QuestionKind.relationship,
        hasRealQuestion: true,
      );
      expect(
        TarotRecurrenceContext.evaluate(
          currentQuestion: rel,
          currentCards: const [],
          historical: hist,
          matchedOccurrence: occ,
        ).summaryKey,
        TarotRecurrenceContext.kindToken,
      );

      final guidance = QuestionGrounding(
        rawText: 'loyalty partner worries',
        topic: null,
        kind: QuestionKind.guidance,
        hasRealQuestion: true,
      );
      expect(
        TarotRecurrenceContext.evaluate(
          currentQuestion: guidance,
          currentCards: const [],
          historical: hist,
          matchedOccurrence: occ,
        ).overlaps,
        isFalse,
      );
    });

    test('stopword-only tokens → false', () {
      final q = QuestionGrounding(
        rawText: 'this that with from',
        topic: null,
        kind: QuestionKind.relationship,
        hasRealQuestion: true,
      );
      final hist = histReading(
        readingId: 'h1',
        at: nowFixed.subtract(const Duration(days: 1)),
        questionKind: QuestionKind.relationship,
        intentionSummary: 'this that with from',
        cardId: major00,
      );
      expect(
        TarotRecurrenceContext.evaluate(
          currentQuestion: q,
          currentCards: const [],
          historical: hist,
          matchedOccurrence: occ,
        ).overlaps,
        isFalse,
      );
    });

    test('keyword_map TR/EN/RU aliases', () {
      final cards = [cardEvidence(kNarrativeMajor06, positionIndex: 0)];
      final q = NarrativeQuestionGrounding.from(rawQuestion: null);

      for (final intention in [
        'partner gelecek',
        'relationship path',
        'партнер путь',
      ]) {
        final hist = histReading(
          readingId: 'h1',
          at: nowFixed.subtract(const Duration(days: 1)),
          intentionSummary: intention,
          cardId: major00,
        );
        final m = TarotRecurrenceContext.evaluate(
          currentQuestion: q,
          currentCards: cards,
          historical: hist,
          matchedOccurrence: occ,
        );
        expect(m.overlaps, isTrue, reason: intention);
        expect(m.summaryKey, TarotRecurrenceContext.keywordMap);
      }
    });

    test('interpretationSummary ignored; same card/spread alone false', () {
      final cards = [cardEvidence(kNarrativeMajor06, positionIndex: 0)];
      final q = NarrativeQuestionGrounding.from(rawQuestion: null);
      final hist = histReading(
        readingId: 'h1',
        at: nowFixed.subtract(const Duration(days: 1)),
        spreadId: 'single',
        cardId: major06,
        interpretationSummary: 'relationship intimacy partner',
      );
      final m = TarotRecurrenceContext.evaluate(
        currentQuestion: q,
        currentCards: cards,
        historical: hist,
        matchedOccurrence: occ,
      );
      expect(m.overlaps, isFalse);
    });

    test('precedence topic > kind_token > keyword_map', () {
      expect(
        TarotRecurrenceContext.strongestKey([
          TarotRecurrenceContext.keywordMap,
          TarotRecurrenceContext.topicMatch,
          TarotRecurrenceContext.kindToken,
        ]),
        TarotRecurrenceContext.topicMatch,
      );
      expect(
        TarotRecurrenceContext.strongestKey([
          TarotRecurrenceContext.keywordMap,
          TarotRecurrenceContext.kindToken,
        ]),
        TarotRecurrenceContext.kindToken,
      );

      final cards = [cardEvidence(kNarrativeMajor06, positionIndex: 0)];
      final q = QuestionGrounding(
        rawText: 'loyalty partner worries',
        topic: 'ilişki',
        kind: QuestionKind.relationship,
        hasRealQuestion: true,
      );
      final hist = histReading(
        readingId: 'h1',
        at: nowFixed.subtract(const Duration(days: 1)),
        topicId: 'ilişki',
        questionKind: QuestionKind.relationship,
        intentionSummary: 'loyalty partner',
        cardId: major00,
      );
      final m = TarotRecurrenceContext.evaluate(
        currentQuestion: q,
        currentCards: cards,
        historical: hist,
        matchedOccurrence: occ,
      );
      expect(m.summaryKey, TarotRecurrenceContext.topicMatch);
    });

    test('kariyer alias hits magician craft keywords', () {
      final cards = [cardEvidence(kNarrativeMajor01, positionIndex: 0)];
      final hist = histReading(
        readingId: 'h1',
        at: nowFixed.subtract(const Duration(days: 1)),
        intentionSummary: 'kariyer değişimi',
        cardId: major00,
      );
      final m = TarotRecurrenceContext.evaluate(
        currentQuestion: NarrativeQuestionGrounding.from(),
        currentCards: cards,
        historical: hist,
        matchedOccurrence: occ,
      );
      expect(m.summaryKey, TarotRecurrenceContext.keywordMap);
    });
  });
}
