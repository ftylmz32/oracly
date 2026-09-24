/// Phase 6C.2 — recurrence count + overlap coherence red-team.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_recurrence_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import 'narrative_prompt_test_support.dart';

void main() {
  test('recurrence count and overlap contracts', () {
    final three = buildFromCorpusId('three_contrast_exemplar_en');
    final a = three.cards.first;
    final at = DateTime.utc(2026, 1, 1);
    RecurringOccurrence occ() => RecurringOccurrence(
          readingId: 'h',
          at: at,
          spreadId: 'classical.single',
          positionKey: 'sign',
          isReversed: false,
        );

    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          three,
          relationships: const [],
          recurringCards: [
            TarotRecurringCardEvidence(
              evidenceId: 'rc',
              canonicalCardId: a.canonicalCardId,
              occurrenceCount: 0,
              contextsOverlap: false,
              occurrences: const [],
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
          relationships: const [],
          recurringCards: [
            TarotRecurringCardEvidence(
              evidenceId: 'rc',
              canonicalCardId: a.canonicalCardId,
              occurrenceCount: 1,
              contextsOverlap: false,
              occurrences: [occ(), occ()],
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          three,
          relationships: const [],
          recurringCards: [
            TarotRecurringCardEvidence(
              evidenceId: 'rc',
              canonicalCardId: a.canonicalCardId,
              occurrenceCount: 5,
              contextsOverlap: false,
              occurrences: [occ(), occ()],
            ),
          ],
        ),
      ).recurringCards.first.occurrenceCount,
      5,
    );
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          three,
          relationships: const [],
          recurringCards: [
            TarotRecurringCardEvidence(
              evidenceId: 'rc',
              canonicalCardId: a.canonicalCardId,
              occurrenceCount: 1,
              contextsOverlap: true,
              overlapSummaryKey: null,
              occurrences: [occ()],
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
          relationships: const [],
          recurringCards: [
            TarotRecurringCardEvidence(
              evidenceId: 'rc',
              canonicalCardId: a.canonicalCardId,
              occurrenceCount: 1,
              contextsOverlap: false,
              overlapSummaryKey: 'topic_match',
              occurrences: [occ()],
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
  });
}
