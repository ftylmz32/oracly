/// Phase 6C.1 — unsupported locale / version / memory / Signature semantics.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_card_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import 'narrative_prompt_special_requests.dart';
import 'narrative_prompt_test_support.dart';

void main() {
  test('unsupported locales throw', () {
    final base = buildFromCorpusId('single_open_fool_en');
    for (final lang in ['de', 'EN', '', 'tr-TR']) {
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(base, languageCode: lang),
        ),
        throwsArgumentError,
        reason: lang,
      );
    }
  });

  test('narrative version + question + excluded memory throw', () {
    final base = buildFromCorpusId('single_open_fool_en');
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(base, narrativeTarotVersion: 1),
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          base,
          question: const QuestionGrounding(
            rawText: 'hello',
            topic: null,
            kind: QuestionKind.open,
            hasRealQuestion: false,
          ),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          base,
          memory: TarotNarrativeMemoryEvidence(
            included: false,
            priorReadingCount: 0,
            recentCardNames: const [],
            recurringThemeLabels: const [],
            omitReason: 'empty',
            entries: [
              MemoryEvidenceEntry(
                evidenceRef: 'x',
                kind: MemoryEvidenceKind.memorySummary,
                contentForModel: 'hidden',
              ),
            ],
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('duplicate current card id rejected', () {
    final base = buildFromCorpusId('three_contrast_exemplar_en');
    final a = base.cards[0];
    final b = base.cards[1];
    expect(
      () => NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          base,
          cards: [
            a,
            TarotNarrativeCardEvidence(
              canonicalCardId: a.canonicalCardId,
              ritualCardId: b.ritualCardId,
              isReversed: b.isReversed,
              positionKey: b.positionKey,
              positionIndex: b.positionIndex,
              displayName: b.displayName,
              profileSlice: b.profileSlice,
              imageAsset: b.imageAsset,
            ),
            base.cards[2],
          ],
          relationships: const [],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('signature manual uses real crossroads 5-card semantics', () {
    final r = signatureManualRequest();
    expect(r.spread.spreadId, 'signature.crossroads');
    expect(r.spread.cardCount, 5);
    final input = NarrativeTarotPromptSerializer.serialize(r);
    expect(input.spread.geometryHook, 'linearRow');
    expect(input.cards.map((c) => c.positionKey).toList(), [
      'option_a',
      'option_b',
      'tension',
      'counsel',
      'direction',
    ]);
  });
}
