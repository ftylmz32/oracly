import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_06.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_current_signals.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_memory_relevance.dart';

import 'tarot_history_test_support.dart';

void main() {
  group('TarotMemoryRelevance', () {
    final now = nowFixed;
    final cards = [cardEvidence(kNarrativeMajor06, positionIndex: 0)];
    final cardKw = TarotHistoricalCurrentSignals.currentCardKeywordIds(cards);

    test('theme intersect / two-token / one-token / cardMap / recall', () {
      final q = NarrativeQuestionGrounding.from(
        rawQuestion: 'loyalty partner future path',
        topic: 'ilişki',
      );
      final themes = TarotHistoricalCurrentSignals.currentThemeIds(q);

      expect(
        TarotMemoryRelevance.score(
          record: connectedMemory(
            sourceId: 'a',
            sourceType: TarotConnectedMemorySourceType.coffee,
            at: now,
            themeIds: const ['ilişki'],
            summary: 'x',
          ),
          question: q,
          currentThemes: themes,
          currentCardKeywords: cardKw,
        ),
        0.80,
      );

      expect(
        TarotMemoryRelevance.score(
          record: connectedMemory(
            sourceId: 'b',
            sourceType: TarotConnectedMemorySourceType.coffee,
            at: now,
            themeIds: const [],
            summary: 'loyalty partner elsewhere',
          ),
          question: q,
          currentThemes: const {},
          currentCardKeywords: const {},
        ),
        0.70,
      );

      expect(
        TarotMemoryRelevance.score(
          record: connectedMemory(
            sourceId: 'c',
            sourceType: TarotConnectedMemorySourceType.coffee,
            at: now,
            themeIds: const [],
            summary: 'partner alone here',
          ),
          question: q,
          currentThemes: const {},
          currentCardKeywords: const {},
        ),
        0.0,
      );

      expect(
        TarotMemoryRelevance.score(
          record: connectedMemory(
            sourceId: 'd',
            sourceType: TarotConnectedMemorySourceType.coffee,
            at: now,
            themeIds: const ['ilişki'],
            summary: 'zzz',
          ),
          question: NarrativeQuestionGrounding.from(rawQuestion: null),
          currentThemes: const {},
          currentCardKeywords: cardKw,
        ),
        0.55,
      );

      expect(
        TarotMemoryRelevance.score(
          record: connectedMemory(
            sourceId: 'e',
            sourceType: TarotConnectedMemorySourceType.coffee,
            at: now,
            themeIds: const [],
            summary: 'zzz',
          ),
          question: NarrativeQuestionGrounding.from(
            rawQuestion: 'remember my previous reading quietly',
          ),
          currentThemes: const {},
          currentCardKeywords: const {},
        ),
        0.50,
      );
    });
  });
}
