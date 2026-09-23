/// Phase 3D.1D / 3D.1D.1 — NarrativeEvidenceBuilder validation failures.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_error.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_input.dart';

final _ritual = <String, int>{
  for (var i = 0; i < 78; i++) OraclyTarotBridge.byRitualId(i)!.id: i,
};

void expectCode(void Function() fn, NarrativeEvidenceErrorCode code) {
  expect(
    fn,
    throwsA(
      isA<NarrativeEvidenceException>().having((e) => e.code, 'code', code),
    ),
  );
}

void main() {
  final three = ClassicalSpreadSemantics.byLegacyTypeName('threeCard');

  NarrativeEvidenceCardInput card({
    required String id,
    required String pos,
    required int idx,
    int? ritual,
    bool rev = false,
  }) {
    return NarrativeEvidenceCardInput(
      canonicalCardId: id,
      ritualCardId: ritual ?? _ritual[id]!,
      isReversed: rev,
      positionKey: pos,
      positionIndex: idx,
    );
  }

  test('wrong card count → cardCountMismatch', () {
    expectCode(
      () => NarrativeEvidenceBuilder.build(
        NarrativeEvidenceInput(
          sessionId: 's',
          readingId: 'r',
          languageCode: 'en',
          spreadType: TarotSpreadType.threeCard,
          cards: [
            card(id: 'major_00', pos: 'past', idx: 0),
            card(id: 'major_01', pos: 'present', idx: 1),
          ],
        ),
      ),
      NarrativeEvidenceErrorCode.cardCountMismatch,
    );
  });

  test('duplicate canonical → duplicateCardId', () {
    expectCode(
      () => NarrativeEvidenceBuilder.build(
        NarrativeEvidenceInput(
          sessionId: 's',
          readingId: 'r',
          languageCode: 'en',
          spreadType: TarotSpreadType.threeCard,
          cards: [
            card(id: 'major_00', pos: 'past', idx: 0),
            card(id: 'major_00', pos: 'present', idx: 1),
            card(id: 'major_01', pos: 'future', idx: 2),
          ],
        ),
      ),
      NarrativeEvidenceErrorCode.duplicateCardId,
    );
  });

  test('fake canonical with ritual 0 → unknownCanonicalCardId', () {
    expectCode(
      () => NarrativeEvidenceBuilder.build(
        NarrativeEvidenceInput(
          sessionId: 's',
          readingId: 'r',
          languageCode: 'en',
          spreadType: TarotSpreadType.single,
          cards: [
            const NarrativeEvidenceCardInput(
              canonicalCardId: 'not_a_card',
              ritualCardId: 0,
              isReversed: false,
              positionKey: 'sign',
              positionIndex: 0,
            ),
          ],
        ),
      ),
      NarrativeEvidenceErrorCode.unknownCanonicalCardId,
    );
  });

  test('invalid ritual id → ritualCardMismatch', () {
    expectCode(
      () => NarrativeEvidenceBuilder.build(
        NarrativeEvidenceInput(
          sessionId: 's',
          readingId: 'r',
          languageCode: 'en',
          spreadType: TarotSpreadType.single,
          cards: [card(id: 'major_00', pos: 'sign', idx: 0, ritual: 999)],
        ),
      ),
      NarrativeEvidenceErrorCode.ritualCardMismatch,
    );
  });

  test('ritual maps to wrong canonical → ritualCardMismatch', () {
    expectCode(
      () => NarrativeEvidenceBuilder.build(
        NarrativeEvidenceInput(
          sessionId: 's',
          readingId: 'r',
          languageCode: 'en',
          spreadType: TarotSpreadType.single,
          cards: [
            // ritual 0 is Fool (major_00), claim cups_01
            card(id: 'cups_01', pos: 'sign', idx: 0, ritual: 0),
          ],
        ),
      ),
      NarrativeEvidenceErrorCode.ritualCardMismatch,
    );
  });

  test('profileMissing remains a typed defensive code', () {
    expect(
      NarrativeEvidenceErrorCode.values,
      contains(NarrativeEvidenceErrorCode.profileMissing),
    );
    const err = NarrativeEvidenceException(
      NarrativeEvidenceErrorCode.profileMissing,
      message: 'defensive invariant',
    );
    expect(err.code, NarrativeEvidenceErrorCode.profileMissing);
  });

  test('duplicate position key → duplicatePositionKey', () {
    expectCode(
      () => NarrativeEvidenceBuilder.build(
        NarrativeEvidenceInput(
          sessionId: 's',
          readingId: 'r',
          languageCode: 'en',
          spreadType: TarotSpreadType.threeCard,
          cards: [
            card(id: 'major_00', pos: 'past', idx: 0),
            card(id: 'major_01', pos: 'past', idx: 0),
            card(id: 'major_02', pos: 'future', idx: 2),
          ],
        ),
      ),
      NarrativeEvidenceErrorCode.duplicatePositionKey,
    );
  });

  test('unknown position key → unknownPositionKey', () {
    expectCode(
      () => NarrativeEvidenceBuilder.build(
        NarrativeEvidenceInput(
          sessionId: 's',
          readingId: 'r',
          languageCode: 'en',
          spreadType: TarotSpreadType.threeCard,
          cards: [
            card(id: 'major_00', pos: 'past', idx: 0),
            card(id: 'major_01', pos: 'present', idx: 1),
            card(id: 'major_02', pos: 'not_a_slot', idx: 2),
          ],
        ),
      ),
      NarrativeEvidenceErrorCode.unknownPositionKey,
    );
  });

  test('wrong position index → spreadMismatch', () {
    expectCode(
      () => NarrativeEvidenceBuilder.build(
        NarrativeEvidenceInput(
          sessionId: 's',
          readingId: 'r',
          languageCode: 'en',
          spreadType: TarotSpreadType.threeCard,
          cards: [
            card(id: 'major_00', pos: 'past', idx: 0),
            card(id: 'major_01', pos: 'present', idx: 1),
            card(id: 'major_02', pos: 'future', idx: 99),
          ],
        ),
      ),
      NarrativeEvidenceErrorCode.spreadMismatch,
    );
  });

  test('exact count + unique valid keys ⇒ exact position-set coverage', () {
    // Production keeps a defensive coverage check, but with a valid semantic
    // catalog it is implied by: cardCount match + every key known + no
    // duplicate keys. Do not invent broken catalog rows to force the branch.
    final keys = three.positions.map((p) => p.positionKey).toSet();
    expect(three.cardCount, keys.length);
    expect(keys, hasLength(3));
    expect(keys, containsAll(['past', 'present', 'future']));
  });
}
