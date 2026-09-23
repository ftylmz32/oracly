import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_06.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_theme_recurrence_engine.dart';

import 'tarot_history_test_support.dart';

void main() {
  group('TarotThemeRecurrenceEngine', () {
    final now = nowFixed;

    TarotNarrativeRequest relBase() => baseRequest(
      forceKind: QuestionKind.relationship,
      questionRaw: 'Should I stay with my partner?',
      cards: [cardEvidence(kNarrativeMajor06, positionIndex: 0)],
    );

    test('same-type monoculture rejected; cross-type qualifies', () {
      final base = relBase();
      expect(
        TarotThemeRecurrenceEngine.build(
          base: base,
          history: TarotHistoricalSnapshot(
            tarotReadings: const [],
            connectedMemories: [
              connectedMemory(
                sourceId: 't1',
                sourceType: TarotConnectedMemorySourceType.tarot,
                at: now.subtract(const Duration(days: 1)),
              ),
              connectedMemory(
                sourceId: 't2',
                sourceType: TarotConnectedMemorySourceType.tarot,
                at: now.subtract(const Duration(days: 2)),
              ),
            ],
          ),
          now: now,
        ),
        isEmpty,
      );

      final out = TarotThemeRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: const [],
          connectedMemories: [
            connectedMemory(
              sourceId: 't1',
              sourceType: TarotConnectedMemorySourceType.tarot,
              at: now.subtract(const Duration(days: 1)),
            ),
            connectedMemory(
              sourceId: 'c1',
              sourceType: TarotConnectedMemorySourceType.coffee,
              at: now.subtract(const Duration(days: 2)),
            ),
          ],
        ),
        now: now,
      );
      expect(out, hasLength(1));
      expect(out.single.evidenceId, 'rec_theme_01');
      expect(out.single.themeIdOrLabel, 'ilişki');
      expect(out.single.supportCount, 2);
      expect(out.single.relevanceToCurrentAsk, 0.80);
      expect(out.single.supportingReadingIds, ['tarot:t1', 'coffee:c1']);
    });

    test('same raw sourceId across types stays distinct', () {
      final out = TarotThemeRecurrenceEngine.build(
        base: relBase(),
        history: TarotHistoricalSnapshot(
          tarotReadings: const [],
          connectedMemories: [
            connectedMemory(
              sourceId: 'same_id',
              sourceType: TarotConnectedMemorySourceType.tarot,
              at: now.subtract(const Duration(days: 1)),
            ),
            connectedMemory(
              sourceId: 'same_id',
              sourceType: TarotConnectedMemorySourceType.coffee,
              at: now.subtract(const Duration(days: 2)),
            ),
          ],
        ),
        now: now,
      );
      expect(out.single.supportCount, 2);
      expect(
        out.single.supportingReadingIds,
        containsAll(['tarot:same_id', 'coffee:same_id']),
      );
    });

    test('summary-only theme word does not authorize theme recurrence', () {
      final out = TarotThemeRecurrenceEngine.build(
        base: relBase(),
        history: TarotHistoricalSnapshot(
          tarotReadings: const [],
          connectedMemories: [
            connectedMemory(
              sourceId: 't1',
              sourceType: TarotConnectedMemorySourceType.tarot,
              at: now.subtract(const Duration(days: 1)),
              themeIds: const [],
              summary: 'relationship partner intimacy',
            ),
            connectedMemory(
              sourceId: 'c1',
              sourceType: TarotConnectedMemorySourceType.coffee,
              at: now.subtract(const Duration(days: 2)),
              themeIds: const [],
              summary: 'relationship partner intimacy',
            ),
          ],
        ),
        now: now,
      );
      expect(out, isEmpty);
    });

    test('current-spread themeRepetition alone → no historical themes', () {
      final base = TarotNarrativeRequest(
        narrativeTarotVersion: 2,
        languageCode: 'en',
        sessionId: 's',
        readingId: 'r',
        question: NarrativeQuestionGrounding.from(
          rawQuestion: 'Should I stay?',
        ),
        spread: ClassicalSpreadSemantics.byLegacyTypeName('single'),
        cards: [cardEvidence(kNarrativeMajor06, positionIndex: 0)],
        relationships: const [
          TarotNarrativeRelationshipEvidence(
            evidenceId: 'rel_01',
            leftCardId: 'major_06',
            rightCardId: 'major_00',
            leftPositionKey: 'sign',
            rightPositionKey: 'sign',
            kind: RelationshipKind.themeRepetition,
            provenance: 'test',
            strength: 0.9,
          ),
        ],
        memory: TarotNarrativeMemoryEvidence.empty,
        recurringCards: const [],
        recurringThemes: const [],
        bounds: RequestBounds.defaults,
      );
      expect(
        TarotThemeRecurrenceEngine.build(
          base: base,
          history: TarotHistoricalSnapshot(
            tarotReadings: const [],
            connectedMemories: const [],
          ),
          now: now,
        ),
        isEmpty,
      );
    });

    test('maxThemeLabels 4 + ids; duplicate source counts once', () {
      final themes = [
        'ilişki',
        'karar',
        'değişim',
        'sınır',
        'kariyer',
        'iletişim',
      ];
      final memories = <TarotConnectedMemoryRecord>[];
      for (final theme in themes) {
        memories.add(
          connectedMemory(
            sourceId: 't_$theme',
            sourceType: TarotConnectedMemorySourceType.tarot,
            at: now.subtract(const Duration(days: 1)),
            themeIds: [theme],
          ),
        );
        memories.add(
          connectedMemory(
            sourceId: 'c_$theme',
            sourceType: TarotConnectedMemorySourceType.coffee,
            at: now.subtract(const Duration(days: 2)),
            themeIds: [theme],
          ),
        );
      }
      // duplicate of first pair
      memories.add(
        connectedMemory(
          sourceId: 't_ilişki',
          sourceType: TarotConnectedMemorySourceType.tarot,
          at: now.subtract(const Duration(hours: 1)),
          themeIds: const ['ilişki'],
        ),
      );

      final base = baseRequest(
        forceKind: QuestionKind.relationship,
        questionRaw:
            'remember previous relationship karar değişim sınır kariyer iletişim partner',
        cards: [cardEvidence(kNarrativeMajor06, positionIndex: 0)],
      );
      final out = TarotThemeRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: const [],
          connectedMemories: memories,
        ),
        now: now,
      );
      expect(out, hasLength(4));
      expect(out.map((e) => e.evidenceId).toList(), [
        'rec_theme_01',
        'rec_theme_02',
        'rec_theme_03',
        'rec_theme_04',
      ]);
      final iliski = out.firstWhere((e) => e.themeIdOrLabel == 'ilişki');
      expect(iliski.supportCount, 2);
    });
  });
}
