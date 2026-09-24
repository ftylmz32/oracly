/// Phase 6C.2 — theme/memory scalars + question max length.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_recurrence_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';
import 'package:oracly_new/features/tarot/reading/reading_question.dart';

import 'narrative_prompt_test_support.dart';

void main() {
  test('theme/memory scalars and question max', () {
    final three = buildFromCorpusId('three_contrast_exemplar_en');
    final a = three.cards.first;
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          three,
          relationships: const [],
          recurringThemes: [
            TarotRecurringThemeEvidence(
              evidenceId: 't',
              themeIdOrLabel: 'x',
              supportCount: 1,
              supportingReadingIds: const ['a'],
              relatedCardIds: [a.canonicalCardId],
              relevanceToCurrentAsk: 0.5,
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
    for (final r in [double.nan, double.infinity, -0.01, 1.01]) {
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(
            three,
            relationships: const [],
            recurringThemes: [
              TarotRecurringThemeEvidence(
                evidenceId: 't',
                themeIdOrLabel: 'x',
                supportCount: 2,
                supportingReadingIds: const ['a', 'b'],
                relatedCardIds: [a.canonicalCardId],
                relevanceToCurrentAsk: r,
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
    }
    for (final c in [double.nan, double.infinity, -0.1, 1.1]) {
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(
            three,
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
                  contentForModel: 'ok',
                  confidence: c,
                ),
              ],
            ),
          ),
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          three,
          relationships: const [],
          question: QuestionGrounding(
            rawText: 'q' * (ReadingQuestion.maxLength + 1),
            topic: null,
            kind: QuestionKind.open,
            hasRealQuestion: true,
          ),
        ),
      ),
      throwsArgumentError,
    );
  });
}
