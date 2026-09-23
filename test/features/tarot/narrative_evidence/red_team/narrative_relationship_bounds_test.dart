/// Phase 3D.1C.1 — max relationships / max cards absolute bounds.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_error.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_context.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_selector.dart';

import '../narrative_relationship_test_support.dart';

void main() {
  List<NarrativeRelationshipCardContext> cardsForCeltic(int n) {
    final positions = celtic().positions;
    final rare = NarrativeKeywordIds.abundance;
    return [
      for (var i = 0; i < n; i++)
        ctx(
          id: 'card_$i',
          positionKey: positions[i].positionKey,
          positionIndex: positions[i].index,
          keywordIds: [rare, NarrativeKeywordIds.attachment],
          relatedIds: [
            for (var j = 0; j < n; j++)
              if (j != i) 'card_$j',
          ],
        ),
    ];
  }

  test('maxRelationships=100 → output <=12', () {
    final out = NarrativeRelationshipSelector.select(
      cards: cardsForCeltic(8),
      spread: celtic(),
      questionKind: QuestionKind.open,
      maxRelationships: 100,
    );
    expect(out.length, lessThanOrEqualTo(12));
    expect(out, isNotEmpty);
  });

  test('maxRelationships=-5 → empty', () {
    final out = NarrativeRelationshipSelector.select(
      cards: cardsForCeltic(3),
      spread: celtic(),
      questionKind: QuestionKind.open,
      maxRelationships: -5,
    );
    expect(out, isEmpty);
  });

  test('maxRelationships=5 → <=5', () {
    final out = NarrativeRelationshipSelector.select(
      cards: cardsForCeltic(8),
      spread: celtic(),
      questionKind: QuestionKind.open,
      maxRelationships: 5,
    );
    expect(out.length, lessThanOrEqualTo(5));
  });

  test('10 cards allowed', () {
    expect(
      () => NarrativeRelationshipSelector.select(
        cards: cardsForCeltic(10),
        spread: celtic(),
        questionKind: QuestionKind.open,
      ),
      returnsNormally,
    );
  });

  test('11 cards → cardCountMismatch', () {
    // Fabricate 11 prepared contexts (11th reuses last position key for ceiling test).
    final ten = cardsForCeltic(10);
    final extra = ctx(
      id: 'card_10',
      positionKey: 'outcome',
      positionIndex: 9,
      keywordIds: [NarrativeKeywordIds.abundance],
    );
    expect(
      () => NarrativeRelationshipSelector.select(
        cards: [...ten, extra],
        spread: celtic(),
        questionKind: QuestionKind.open,
      ),
      throwsA(
        isA<NarrativeEvidenceException>().having(
          (e) => e.code,
          'code',
          NarrativeEvidenceErrorCode.cardCountMismatch,
        ),
      ),
    );
  });
}
