/// Shared rich-history fixture for enricher unit tests (Phase 4D).
library;

import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';

import 'tarot_history_test_support.dart';

TarotHistoricalSnapshot enricherRichHistory(
  TarotNarrativeRequest base,
  DateTime now,
) {
  return TarotHistoricalSnapshot(
    tarotReadings: [
      histReading(
        readingId: 'h1',
        at: now.subtract(const Duration(days: 3)),
        cardId: major00,
        questionKind: QuestionKind.relationship,
        topicId: 'love',
        intentionSummary: 'relationship loyalty partner stay',
      ),
      histReading(
        readingId: 'h2',
        at: now.subtract(const Duration(days: 5)),
        cardId: major00,
        questionKind: QuestionKind.relationship,
        topicId: 'love',
        intentionSummary: 'relationship loyalty partner stay',
      ),
    ],
    connectedMemories: [
      connectedMemory(
        sourceId: 'c1',
        sourceType: TarotConnectedMemorySourceType.coffee,
        at: now.subtract(const Duration(days: 2)),
        themeIds: const ['ilişki'],
        summary: 'shared loyalty partner reflection coffee',
      ),
      connectedMemory(
        sourceId: 'd1',
        sourceType: TarotConnectedMemorySourceType.dream,
        at: now.subtract(const Duration(days: 4)),
        themeIds: const ['ilişki'],
        summary: 'shared loyalty partner reflection dream',
      ),
    ],
  );
}
