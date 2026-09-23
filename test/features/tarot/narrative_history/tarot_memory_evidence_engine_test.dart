import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_06.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_memory_evidence_engine.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_memory_evidence_support.dart';

import 'tarot_history_test_support.dart';

void main() {
  group('TarotMemoryEvidenceEngine', () {
    final now = nowFixed;

    test('omitReason contracts + hints empty', () {
      final base = baseRequest(
        cards: [cardEvidence(kNarrativeMajor06, positionIndex: 0)],
      );
      final none = TarotMemoryEvidenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(tarotReadings: const []),
        now: now,
        eligiblePriorReadingCount: 0,
      );
      expect(none.included, isFalse);
      expect(none.omitReason, 'no_history');

      final emptyConnected = TarotMemoryEvidenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(tarotReadings: const []),
        now: now,
        eligiblePriorReadingCount: 3,
      );
      expect(emptyConnected.omitReason, 'empty');

      final irrelevant = TarotMemoryEvidenceEngine.build(
        base: baseRequest(questionRaw: null, topic: null),
        history: TarotHistoricalSnapshot(
          tarotReadings: const [],
          connectedMemories: [
            connectedMemory(
              sourceId: 'c1',
              sourceType: TarotConnectedMemorySourceType.coffee,
              at: now.subtract(const Duration(days: 1)),
              themeIds: const ['karar'],
              summary: 'zzzz',
            ),
          ],
        ),
        now: now,
        eligiblePriorReadingCount: 2,
      );
      expect(irrelevant.omitReason, 'irrelevant');
      expect(irrelevant.recentCardNames, isEmpty);
      expect(irrelevant.recurringThemeLabels, isEmpty);
    });

    test(
      'bounds 4 entries / 220 / 800; epistemic prefix; no sourceId in content',
      () {
        final memories = [
          for (var i = 0; i < 6; i++)
            connectedMemory(
              sourceId: 'c$i',
              sourceType: TarotConnectedMemorySourceType.coffee,
              at: now.subtract(Duration(days: i + 1)),
              themeIds: const ['ilişki'],
              summary: 'loyalty partner shared ${'word' * 80}',
              epistemic: MemoryEvidenceEpistemic.observation,
            ),
        ];
        final out = TarotMemoryEvidenceEngine.build(
          base: baseRequest(
            forceKind: QuestionKind.relationship,
            questionRaw: 'Should I stay with my partner loyalty?',
            topic: 'ilişki',
            cards: [cardEvidence(kNarrativeMajor06, positionIndex: 0)],
          ),
          history: TarotHistoricalSnapshot(
            tarotReadings: const [],
            connectedMemories: memories,
          ),
          now: now,
          eligiblePriorReadingCount: 2,
        );
        expect(out.included, isTrue);
        expect(out.omitReason, 'included');
        expect(out.entries, hasLength(4));
        expect(out.entries.map((e) => e.evidenceRef).toList(), [
          'mem_01',
          'mem_02',
          'mem_03',
          'mem_04',
        ]);
        var total = 0;
        for (final e in out.entries) {
          expect(e.contentForModel.length, lessThanOrEqualTo(220));
          expect(
            e.contentForModel.startsWith('[OBSERVATION][coffee] '),
            isTrue,
          );
          expect(e.contentForModel.contains(e.sourceId!), isFalse);
          expect(e.epistemic, MemoryEvidenceEpistemic.observation);
          total += e.contentForModel.length;
        }
        expect(total, lessThanOrEqualTo(800));
      },
    );

    test('maxMemoryChars 0 / tiny → no entries', () {
      final base = baseRequest(
        bounds: const RequestBounds(
          maxPriorReadingsScanned: 20,
          maxRecurringOccurrencesListed: 5,
          maxRelationships: 12,
          maxMemoryChars: 0,
          maxThemeLabels: 4,
        ),
        forceKind: QuestionKind.relationship,
        topic: 'ilişki',
        cards: [cardEvidence(kNarrativeMajor06, positionIndex: 0)],
      );
      final out = TarotMemoryEvidenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: const [],
          connectedMemories: [
            connectedMemory(
              sourceId: 'c1',
              sourceType: TarotConnectedMemorySourceType.coffee,
              at: now.subtract(const Duration(days: 1)),
            ),
          ],
        ),
        now: now,
        eligiblePriorReadingCount: 1,
      );
      expect(out.entries, isEmpty);
      expect(out.included, isFalse);
    });

    test('ranking score coefficients + immutable entries', () {
      final newer = connectedMemory(
        sourceId: 'a',
        sourceType: TarotConnectedMemorySourceType.coffee,
        at: now.subtract(const Duration(days: 1)),
        confidence: 1.0,
      );
      final older = connectedMemory(
        sourceId: 'b',
        sourceType: TarotConnectedMemorySourceType.coffee,
        at: now.subtract(const Duration(days: 30)),
        confidence: 1.0,
      );
      final sNew = TarotMemoryEvidenceSupport.rankingScore(
        relevance: 0.8,
        confidence: 1.0,
        occurredAt: newer.occurredAt,
        nowUtc: now,
      );
      final sOld = TarotMemoryEvidenceSupport.rankingScore(
        relevance: 0.8,
        confidence: 1.0,
        occurredAt: older.occurredAt,
        nowUtc: now,
      );
      expect(sNew, greaterThan(sOld));

      final out = TarotMemoryEvidenceEngine.build(
        base: baseRequest(
          forceKind: QuestionKind.relationship,
          topic: 'ilişki',
          cards: [cardEvidence(kNarrativeMajor06, positionIndex: 0)],
        ),
        history: TarotHistoricalSnapshot(
          tarotReadings: const [],
          connectedMemories: [older, newer],
        ),
        now: now,
        eligiblePriorReadingCount: 1,
      );
      expect(out.entries.first.sourceId, 'a');
      expect(() => out.entries.add(out.entries.first), throwsUnsupportedError);
    });

    test('explicit recall includes source-backed memory at 0.50 path', () {
      final out = TarotMemoryEvidenceEngine.build(
        base: baseRequest(
          questionRaw: 'remember my previous reading please',
          cards: [cardEvidence(kNarrativeMajor06, positionIndex: 0)],
        ),
        history: TarotHistoricalSnapshot(
          tarotReadings: const [],
          connectedMemories: [
            connectedMemory(
              sourceId: 'c1',
              sourceType: TarotConnectedMemorySourceType.coffee,
              at: now.subtract(const Duration(days: 1)),
              themeIds: const [],
              summary: 'zzzz unrelated',
              epistemic: MemoryEvidenceEpistemic.interpretation,
            ),
          ],
        ),
        now: now,
        eligiblePriorReadingCount: 0,
      );
      expect(out.included, isTrue);
      expect(
        out.entries.single.contentForModel,
        startsWith('[INTERPRETATION][coffee] '),
      );
    });
  });
}
