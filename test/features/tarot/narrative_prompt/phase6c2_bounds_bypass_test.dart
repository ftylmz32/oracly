/// Phase 6C.2 — loosened-bound bypass attempts fail closed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_recurrence_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import 'narrative_prompt_test_support.dart';

void main() {
  test('loosened memory/relationship/occurrence/theme bypass rejected', () {
    final three = buildFromCorpusId('three_contrast_exemplar_en');
    final card = three.cards.first;
    const loose = RequestBounds(
      maxPriorReadingsScanned: 20,
      maxRecurringOccurrencesListed: 10,
      maxRelationships: 20,
      maxMemoryChars: 1000,
      maxThemeLabels: 10,
    );
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          three,
          bounds: loose,
          relationships: [
            for (var i = 0; i < 13; i++)
              TarotNarrativeRelationshipEvidence(
                evidenceId: 'r$i',
                leftCardId: three.cards[0].canonicalCardId,
                rightCardId: three.cards[1].canonicalCardId,
                leftPositionKey: three.cards[0].positionKey,
                rightPositionKey: three.cards[1].positionKey,
                kind: RelationshipKind.contrast,
                provenance: 't',
                strength: 0.5,
              ),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          three,
          bounds: loose,
          relationships: const [],
          memory: TarotNarrativeMemoryEvidence(
            included: true,
            priorReadingCount: 1,
            recentCardNames: const [],
            recurringThemeLabels: const [],
            omitReason: 'included',
            entries: [
              MemoryEvidenceEntry(
                evidenceRef: 'm',
                kind: MemoryEvidenceKind.memorySummary,
                contentForModel: 'x' * 900,
              ),
            ],
          ),
        ),
      ),
      throwsArgumentError,
    );
    final at = DateTime.utc(2026, 1, 1);
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          three,
          bounds: loose,
          relationships: const [],
          recurringCards: [
            TarotRecurringCardEvidence(
              evidenceId: 'rc',
              canonicalCardId: card.canonicalCardId,
              occurrenceCount: 6,
              contextsOverlap: false,
              occurrences: [
                for (var i = 0; i < 6; i++)
                  RecurringOccurrence(
                    readingId: 'h$i',
                    at: at,
                    spreadId: 'classical.single',
                    positionKey: 'sign',
                    isReversed: false,
                  ),
              ],
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          three,
          bounds: loose,
          relationships: const [],
          recurringThemes: [
            for (var i = 0; i < 5; i++)
              TarotRecurringThemeEvidence(
                evidenceId: 't$i',
                themeIdOrLabel: 'theme_$i',
                supportCount: 2,
                supportingReadingIds: const ['a', 'b'],
                relatedCardIds: [card.canonicalCardId],
                relevanceToCurrentAsk: 0.5,
              ),
          ],
        ),
      ),
      throwsArgumentError,
    );
  });
}
