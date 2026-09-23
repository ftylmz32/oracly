/// Phase 3D.1C red-team — FR-F01 / FR-F02 sentinels.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_enums.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_context.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_scorer.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_semantic_channel.dart';

void main() {
  NarrativeRelationshipCardContext fromProfile({
    required String cardId,
    required bool reversed,
    required String positionKey,
    required int positionIndex,
    List<String>? relatedIdsOverride,
  }) {
    final profile = NarrativeTarotProfileCatalog.lookup(cardId)!;
    final ori = reversed ? profile.reversed : profile.upright;
    final deckCard = OraclyTarotDeck.byId(cardId)!;
    return NarrativeRelationshipCardContext(
      canonicalCardId: cardId,
      positionKey: positionKey,
      positionIndex: positionIndex,
      isReversed: reversed,
      suit: deckCard.suit,
      number: deckCard.number,
      keywordIds: ori.keywordIds,
      semanticChannel: NarrativeSemanticChannel.from(
        keywordIds: ori.keywordIds,
        symbolTags: profile.symbolTags,
      ),
      transforms: ori.transforms,
      relatedIds:
          relatedIdsOverride ?? deckCard.relationshipWithOtherCards.relatedIds,
    );
  }

  test('FR-F01 production pages: keywordIds equal; semantics may differ', () {
    final w = fromProfile(
      cardId: 'wands_11',
      reversed: false,
      positionKey: 'past',
      positionIndex: 0,
    );
    final p = fromProfile(
      cardId: 'pentacles_11',
      reversed: false,
      positionKey: 'present',
      positionIndex: 1,
    );
    expect(w.keywordIds.toSet(), p.keywordIds.toSet());
    expect(w.suit, isNot(p.suit));
    expect(w.number, OraclyTarotRanks.page);
    expect(p.number, OraclyTarotRanks.page);
    // symbol tags differ → semantic channels may differ
    expect(
      w.semanticChannel.semanticIds.toSet(),
      isNot(p.semanticChannel.semanticIds.toSet()),
    );
  });

  test('FR-F01 identity only REJECT', () {
    final w = fromProfile(
      cardId: 'wands_11',
      reversed: false,
      positionKey: 'self',
      positionIndex: 6,
      relatedIdsOverride: const [],
    );
    final p = fromProfile(
      cardId: 'pentacles_11',
      reversed: false,
      positionKey: 'outcome',
      positionIndex: 9,
      relatedIdsOverride: const [],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: w,
      b: p,
      spread: ClassicalSpreadSemantics.byLegacyTypeName('celticCross'),
      questionKind: QuestionKind.open,
    );
    expect(ev.pageSuitGuard, isTrue);
    expect(ev.breakdown.overlap, lessThanOrEqualTo(0.35));
    expect(ev.normalAdmitted, isFalse);
    expect(ev.provenanceTokens, contains('pageSuitGuard'));
  });

  test('FR-F01 + canonical only 0.90 REJECT', () {
    final w = fromProfile(
      cardId: 'wands_11',
      reversed: false,
      positionKey: 'self',
      positionIndex: 6,
      relatedIdsOverride: const ['pentacles_11'],
    );
    final p = fromProfile(
      cardId: 'pentacles_11',
      reversed: false,
      positionKey: 'outcome',
      positionIndex: 9,
      relatedIdsOverride: const [],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: w,
      b: p,
      spread: ClassicalSpreadSemantics.byLegacyTypeName('celticCross'),
      questionKind: QuestionKind.open,
    );
    expect(ev.pageSuitGuard, isTrue);
    expect(ev.breakdown.total, closeTo(0.90, 1e-6));
    expect(ev.normalAdmitted, isFalse);
  });

  test('FR-F01 + canonical + opposition admit strength<=0.45', () {
    final w = fromProfile(
      cardId: 'wands_11',
      reversed: false,
      positionKey: 'present',
      positionIndex: 0,
      relatedIdsOverride: const ['pentacles_11'],
    );
    final p = fromProfile(
      cardId: 'pentacles_11',
      reversed: false,
      positionKey: 'challenge',
      positionIndex: 1,
      relatedIdsOverride: const [],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: w,
      b: p,
      spread: ClassicalSpreadSemantics.byLegacyTypeName('celticCross'),
      questionKind: QuestionKind.open,
    );
    expect(ev.pageSuitGuard, isTrue);
    expect(ev.breakdown.total, closeTo(1.30, 1e-6));
    expect(ev.normalAdmitted, isTrue);
    expect(ev.strength, closeTo(1.30 / 3.5, 1e-6));
    expect(ev.strength, lessThanOrEqualTo(0.45));
    expect(ev.provenanceTokens, contains('pageSuitGuard'));
  });

  test('FR-F02 production swords page/knight reversed keyword equality', () {
    final page = fromProfile(
      cardId: 'swords_11',
      reversed: true,
      positionKey: 'past',
      positionIndex: 0,
    );
    final knight = fromProfile(
      cardId: 'swords_12',
      reversed: true,
      positionKey: 'present',
      positionIndex: 1,
    );
    expect(page.keywordIds.toSet(), knight.keywordIds.toSet());
    expect(page.suit, OraclyTarotSuit.swords);
    expect(knight.suit, OraclyTarotSuit.swords);
  });

  test('FR-F02 identity only REJECT', () {
    final page = fromProfile(
      cardId: 'swords_11',
      reversed: true,
      positionKey: 'self',
      positionIndex: 6,
      relatedIdsOverride: const [],
    );
    final knight = fromProfile(
      cardId: 'swords_12',
      reversed: true,
      positionKey: 'outcome',
      positionIndex: 9,
      relatedIdsOverride: const [],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: page,
      b: knight,
      spread: ClassicalSpreadSemantics.byLegacyTypeName('celticCross'),
      questionKind: QuestionKind.open,
    );
    expect(ev.courtRankGuard, isTrue);
    expect(ev.normalAdmitted, isFalse);
    expect(ev.provenanceTokens, contains('courtRankGuard'));
  });

  test('FR-F02 + supportive 0.65 REJECT', () {
    final five = ClassicalSpreadSemantics.byLegacyTypeName('fiveCard');
    // Synthetic court pair: keyword identity + empty transforms (production
    // swords also share transforms; calibration arithmetic is 0.35+0.30).
    final page = NarrativeRelationshipCardContext(
      canonicalCardId: 'swords_11',
      positionKey: 'challenge',
      positionIndex: 2,
      isReversed: true,
      suit: OraclyTarotSuit.swords,
      number: OraclyTarotRanks.page,
      keywordIds: const ['haste', 'harshSpeech', 'notListening'],
      semanticChannel: NarrativeSemanticChannel.from(
        keywordIds: const ['haste', 'harshSpeech', 'notListening'],
        symbolTags: const [],
      ),
      transforms: const [],
      relatedIds: const [],
    );
    final knight = NarrativeRelationshipCardContext(
      canonicalCardId: 'swords_12',
      positionKey: 'strength',
      positionIndex: 3,
      isReversed: true,
      suit: OraclyTarotSuit.swords,
      number: OraclyTarotRanks.knight,
      keywordIds: const ['haste', 'harshSpeech', 'notListening'],
      semanticChannel: NarrativeSemanticChannel.from(
        keywordIds: const ['haste', 'harshSpeech', 'notListening'],
        symbolTags: const [],
      ),
      transforms: const [],
      relatedIds: const [],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: page,
      b: knight,
      spread: five,
      questionKind: QuestionKind.open,
    );
    expect(ev.courtRankGuard, isTrue);
    expect(ev.breakdown.position, 0.30);
    expect(ev.breakdown.total, closeTo(0.65, 1e-6));
    expect(ev.normalAdmitted, isFalse);
  });

  test('FR-F02 + canonical + opposition admit strength<=0.45', () {
    final page = NarrativeRelationshipCardContext(
      canonicalCardId: 'swords_11',
      positionKey: 'present',
      positionIndex: 0,
      isReversed: true,
      suit: OraclyTarotSuit.swords,
      number: OraclyTarotRanks.page,
      keywordIds: const ['haste', 'harshSpeech', 'notListening'],
      semanticChannel: NarrativeSemanticChannel.from(
        keywordIds: const ['haste', 'harshSpeech', 'notListening'],
        symbolTags: const [],
      ),
      transforms: const [],
      relatedIds: const ['swords_12'],
    );
    final knight = NarrativeRelationshipCardContext(
      canonicalCardId: 'swords_12',
      positionKey: 'challenge',
      positionIndex: 1,
      isReversed: true,
      suit: OraclyTarotSuit.swords,
      number: OraclyTarotRanks.knight,
      keywordIds: const ['haste', 'harshSpeech', 'notListening'],
      semanticChannel: NarrativeSemanticChannel.from(
        keywordIds: const ['haste', 'harshSpeech', 'notListening'],
        symbolTags: const [],
      ),
      transforms: const [],
      relatedIds: const [],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: page,
      b: knight,
      spread: ClassicalSpreadSemantics.byLegacyTypeName('celticCross'),
      questionKind: QuestionKind.open,
    );
    expect(ev.courtRankGuard, isTrue);
    expect(ev.breakdown.total, closeTo(1.30, 1e-6));
    expect(ev.normalAdmitted, isTrue);
    expect(ev.strength, lessThanOrEqualTo(0.45));
  });
}
