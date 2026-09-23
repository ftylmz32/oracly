import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_06.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_card_recurrence_engine.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_memory_evidence_engine.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_theme_recurrence_engine.dart';

import '../tarot_history_test_support.dart';

void main() {
  group('theme/memory red-team', () {
    final now = nowFixed;

    test('card recurrence ignores connectedMemories', () {
      final base = baseRequest();
      final out = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: 'h1',
              at: now.subtract(const Duration(days: 1)),
              cardId: major00,
            ),
          ],
          connectedMemories: [
            connectedMemory(
              sourceId: 'noise',
              sourceType: TarotConnectedMemorySourceType.coffee,
              at: now.subtract(const Duration(days: 1)),
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(out.recurringCards.single.occurrenceCount, 1);
    });

    test('coffee+dream qualifies; three types supportCount 3', () {
      final base = baseRequest(
        forceKind: QuestionKind.relationship,
        cards: [cardEvidence(kNarrativeMajor06, positionIndex: 0)],
      );
      final out = TarotThemeRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: const [],
          connectedMemories: [
            connectedMemory(
              sourceId: 'c',
              sourceType: TarotConnectedMemorySourceType.coffee,
              at: now.subtract(const Duration(days: 1)),
            ),
            connectedMemory(
              sourceId: 'd',
              sourceType: TarotConnectedMemorySourceType.dream,
              at: now.subtract(const Duration(days: 2)),
            ),
            connectedMemory(
              sourceId: 'p',
              sourceType: TarotConnectedMemorySourceType.palm,
              at: now.subtract(const Duration(days: 3)),
            ),
          ],
        ),
        now: now,
      );
      expect(out.single.supportCount, 3);
    });

    test('unknown theme + outside window ignored', () {
      final base = baseRequest(
        forceKind: QuestionKind.relationship,
        cards: [cardEvidence(kNarrativeMajor06, positionIndex: 0)],
      );
      expect(
        TarotThemeRecurrenceEngine.build(
          base: base,
          history: TarotHistoricalSnapshot(
            tarotReadings: const [],
            connectedMemories: [
              connectedMemory(
                sourceId: 'c',
                sourceType: TarotConnectedMemorySourceType.coffee,
                at: now.subtract(const Duration(days: 1)),
                themeIds: const ['unknown_theme'],
              ),
              connectedMemory(
                sourceId: 'd',
                sourceType: TarotConnectedMemorySourceType.dream,
                at: now.subtract(const Duration(days: 100)),
              ),
            ],
          ),
          now: now,
        ),
        isEmpty,
      );
    });

    test('memory generic question does not dump history', () {
      final out = TarotMemoryEvidenceEngine.build(
        base: baseRequest(questionRaw: null, topic: 'general'),
        history: TarotHistoricalSnapshot(
          tarotReadings: const [],
          connectedMemories: [
            connectedMemory(
              sourceId: 'c',
              sourceType: TarotConnectedMemorySourceType.coffee,
              at: now.subtract(const Duration(days: 1)),
              themeIds: const [],
              summary: 'recent coffee note without themes',
            ),
          ],
        ),
        now: now,
        eligiblePriorReadingCount: 1,
      );
      expect(out.omitReason, 'irrelevant');
    });
  });
}
