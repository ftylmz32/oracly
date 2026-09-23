/// Phase 3D.1C — score components, admission, overlap/contrast/transform.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_enums.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_keyword_contrasts.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_keyword_discrimination.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_scorer.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_rules.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';

import 'narrative_relationship_test_support.dart';

void main() {
  group('overlap + families', () {
    test('normalized overlap uses weight/6 not raw IDF', () {
      final id = NarrativeKeywordIds.abundance; // df=1, rare
      final w = NarrativeKeywordDiscrimination.weight(id);
      final a = ctx(
        id: 'a',
        positionKey: 'past',
        positionIndex: 0,
        keywordIds: [id],
      );
      final b = ctx(
        id: 'b',
        positionKey: 'present',
        positionIndex: 1,
        keywordIds: [id],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: threeCard(),
        questionKind: QuestionKind.open,
      );
      expect(ev.breakdown.overlap, closeTo(w / 6.0, 1e-9));
      expect(ev.breakdown.overlap, isNot(closeTo(w, 1e-3)));
    });

    test('one HF shared id alone: reject', () {
      final a = ctx(
        id: 'a',
        positionKey: 'self',
        positionIndex: 6,
        keywordIds: [NarrativeKeywordIds.haste],
      );
      final b = ctx(
        id: 'b',
        positionKey: 'outcome',
        positionIndex: 9,
        keywordIds: [NarrativeKeywordIds.haste],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: celtic(),
        questionKind: QuestionKind.open,
      );
      expect(ev.independentFamilyCount, 1);
      expect(ev.normalAdmitted, isFalse);
    });

    test('one rare shared id alone: reject', () {
      final a = ctx(
        id: 'a',
        positionKey: 'self',
        positionIndex: 6,
        keywordIds: [NarrativeKeywordIds.abundance],
      );
      final b = ctx(
        id: 'b',
        positionKey: 'outcome',
        positionIndex: 9,
        keywordIds: [NarrativeKeywordIds.abundance],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: celtic(),
        questionKind: QuestionKind.open,
      );
      expect(ev.independentFamilyCount, 1);
      expect(ev.normalAdmitted, isFalse);
    });

    test('two shared ids = still one SEMANTIC family', () {
      final a = ctx(
        id: 'a',
        positionKey: 'self',
        positionIndex: 6,
        keywordIds: [
          NarrativeKeywordIds.abundance,
          NarrativeKeywordIds.attachment,
        ],
      );
      final b = ctx(
        id: 'b',
        positionKey: 'outcome',
        positionIndex: 9,
        keywordIds: [
          NarrativeKeywordIds.abundance,
          NarrativeKeywordIds.attachment,
        ],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: celtic(),
        questionKind: QuestionKind.open,
      );
      expect(ev.independentFamilyCount, 1);
      expect(ev.standardPath, isFalse);
    });

    test('HF + canonical: admits via canonical path (S>=1.0)', () {
      final a = ctx(
        id: 'a',
        positionKey: 'self',
        positionIndex: 6,
        keywordIds: [NarrativeKeywordIds.haste],
        relatedIds: ['b'],
      );
      final b = ctx(
        id: 'b',
        positionKey: 'outcome',
        positionIndex: 9,
        keywordIds: [NarrativeKeywordIds.haste],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: celtic(),
        questionKind: QuestionKind.open,
      );
      final expected =
          NarrativeKeywordDiscrimination.weight(NarrativeKeywordIds.haste) /
              6.0 +
          NarrativeRelationshipRules.canonicalBonus;
      expect(ev.breakdown.total, closeTo(expected, 1e-9));
      expect(ev.independentFamilyCount, 2);
      expect(ev.breakdown.total, greaterThanOrEqualTo(1.0));
      expect(ev.canonicalPath, isTrue);
      expect(ev.normalAdmitted, isTrue);
    });

    test('rare + canonical admits when S>=1.0 and families>=2', () {
      final a = ctx(
        id: 'a',
        positionKey: 'self',
        positionIndex: 6,
        keywordIds: [NarrativeKeywordIds.abundance],
        relatedIds: ['b'],
      );
      final b = ctx(
        id: 'b',
        positionKey: 'outcome',
        positionIndex: 9,
        keywordIds: [NarrativeKeywordIds.abundance],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: celtic(),
        questionKind: QuestionKind.open,
      );
      expect(ev.canonicalRelated, isTrue);
      expect(ev.independentFamilyCount, 2);
      expect(ev.breakdown.total, greaterThanOrEqualTo(1.0));
      expect(ev.canonicalPath, isTrue);
      expect(ev.normalAdmitted, isTrue);
    });
  });

  group('contrast transform canonical position question', () {
    test('HARD contrast = 0.70 once; multiple HARD still 0.70', () {
      final a = ctx(
        id: 'a',
        positionKey: 'past',
        positionIndex: 0,
        keywordIds: [NarrativeKeywordIds.balance, NarrativeKeywordIds.clarity],
      );
      final b = ctx(
        id: 'b',
        positionKey: 'present',
        positionIndex: 1,
        keywordIds: [
          NarrativeKeywordIds.imbalance,
          NarrativeKeywordIds.confusion,
        ],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: threeCard(),
        questionKind: QuestionKind.open,
      );
      expect(ev.contrastClass, NarrativeKeywordContrastClass.hard);
      expect(ev.breakdown.contrast, 0.70);
    });

    test('CONTEXTUAL contrast = 0.45 once', () {
      final a = ctx(
        id: 'a',
        positionKey: 'past',
        positionIndex: 0,
        keywordIds: [NarrativeKeywordIds.momentum],
      );
      final b = ctx(
        id: 'b',
        positionKey: 'present',
        positionIndex: 1,
        keywordIds: [NarrativeKeywordIds.haste],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: threeCard(),
        questionKind: QuestionKind.open,
      );
      expect(ev.contrastClass, NarrativeKeywordContrastClass.contextual);
      expect(ev.breakdown.contrast, 0.45);
    });

    test('transform 0.15 each capped at 0.30', () {
      final a = ctx(
        id: 'a',
        positionKey: 'past',
        positionIndex: 0,
        isReversed: true,
        transforms: [
          ReversedTransformKind.delay,
          ReversedTransformKind.excess,
          ReversedTransformKind.blockedExpression,
        ],
      );
      final b = ctx(
        id: 'b',
        positionKey: 'present',
        positionIndex: 1,
        isReversed: true,
        transforms: [
          ReversedTransformKind.delay,
          ReversedTransformKind.excess,
          ReversedTransformKind.blockedExpression,
        ],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: threeCard(),
        questionKind: QuestionKind.open,
      );
      expect(ev.effectiveSharedTransforms.length, greaterThanOrEqualTo(2));
      expect(ev.breakdown.transform, 0.30);
      expect(ev.normalAdmitted, isFalse); // transform alone never admits
    });

    test('canonical 0.55', () {
      final a = ctx(
        id: 'a',
        positionKey: 'past',
        positionIndex: 0,
        relatedIds: ['b'],
      );
      final b = ctx(id: 'b', positionKey: 'present', positionIndex: 1);
      final ev = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: threeCard(),
        questionKind: QuestionKind.open,
      );
      expect(ev.breakdown.canonical, 0.55);
    });

    test('all five position bonuses exact', () {
      expect(
        NarrativeRelationshipRules.positionBonus[PositionEdgeKind.opposition],
        0.40,
      );
      expect(
        NarrativeRelationshipRules.positionBonus[PositionEdgeKind.temporal],
        0.35,
      );
      expect(
        NarrativeRelationshipRules.positionBonus[PositionEdgeKind.supportive],
        0.30,
      );
      expect(
        NarrativeRelationshipRules.positionBonus[PositionEdgeKind.pressure],
        0.35,
      );
      expect(
        NarrativeRelationshipRules.positionBonus[PositionEdgeKind.mirror],
        0.25,
      );

      final past = ctx(
        id: 'a',
        positionKey: 'past',
        positionIndex: 0,
        keywordIds: [NarrativeKeywordIds.abundance],
      );
      final present = ctx(
        id: 'b',
        positionKey: 'present',
        positionIndex: 1,
        keywordIds: [NarrativeKeywordIds.abundance],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: past,
        b: present,
        spread: threeCard(),
        questionKind: QuestionKind.open,
      );
      expect(ev.positionEdgeKind, PositionEdgeKind.temporal);
      expect(ev.breakdown.position, 0.35);
    });

    test('question bonuses exact', () {
      final a = ctx(
        id: 'a',
        positionKey: 'past',
        positionIndex: 0,
        keywordIds: [NarrativeKeywordIds.intimacy],
      );
      final b = ctx(
        id: 'b',
        positionKey: 'present',
        positionIndex: 1,
        keywordIds: [NarrativeKeywordIds.intimacy],
      );
      expect(
        NarrativeRelationshipScorer.evaluate(
          a: a,
          b: b,
          spread: threeCard(),
          questionKind: QuestionKind.open,
        ).breakdown.question,
        0,
      );
      expect(
        NarrativeRelationshipScorer.evaluate(
          a: a,
          b: b,
          spread: threeCard(),
          questionKind: QuestionKind.guidance,
        ).breakdown.question,
        0,
      );
      expect(
        NarrativeRelationshipScorer.evaluate(
          a: a,
          b: b,
          spread: threeCard(),
          questionKind: QuestionKind.relationship,
        ).breakdown.question,
        0.15,
      );

      final d1 = ctx(
        id: 'a',
        positionKey: 'past',
        positionIndex: 0,
        keywordIds: [NarrativeKeywordIds.choice],
      );
      final d2 = ctx(
        id: 'b',
        positionKey: 'present',
        positionIndex: 1,
        keywordIds: [NarrativeKeywordIds.choice],
      );
      expect(
        NarrativeRelationshipScorer.evaluate(
          a: d1,
          b: d2,
          spread: threeCard(),
          questionKind: QuestionKind.decision,
        ).breakdown.question,
        0.15,
      );
      expect(
        NarrativeRelationshipScorer.evaluate(
          a: d1,
          b: d2,
          spread: threeCard(),
          questionKind: QuestionKind.relationship,
        ).breakdown.question,
        0,
      );
    });

    test('tag-only and orientation: 0 score / 0 family', () {
      final a = ctx(
        id: 'a',
        positionKey: 'past',
        positionIndex: 0,
        isReversed: false,
        symbolTags: ['inquiry'], // may be ontology or tag-only
      );
      // Use a known non-ontology tag if needed — craft is in NarrativeSymbolTags
      final left = ctx(
        id: 'a',
        positionKey: 'self',
        positionIndex: 6,
        isReversed: false,
        symbolTags: const ['nonOntologyMotifX'],
      );
      final right = ctx(
        id: 'b',
        positionKey: 'outcome',
        positionIndex: 9,
        isReversed: true,
        symbolTags: const ['nonOntologyMotifX'],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: left,
        b: right,
        spread: celtic(),
        questionKind: QuestionKind.open,
      );
      expect(ev.sharedTagOnlyIds, isNotEmpty);
      expect(ev.breakdown.overlap, 0);
      expect(ev.independentFamilyCount, 0);
      expect(ev.provenanceTokens.contains('orientationPair'), isFalse);
      expect(a.suit, OraclyTarotSuit.cups); // silence unused
    });

    test('S_total clamp 3.5 and strength 0-1', () {
      final a = ctx(
        id: 'a',
        positionKey: 'present',
        positionIndex: 1,
        keywordIds: [
          NarrativeKeywordIds.balance,
          NarrativeKeywordIds.clarity,
          NarrativeKeywordIds.union,
          NarrativeKeywordIds.abundance,
          NarrativeKeywordIds.intimacy,
        ],
        relatedIds: ['b'],
        transforms: [ReversedTransformKind.delay, ReversedTransformKind.excess],
      );
      final b = ctx(
        id: 'b',
        positionKey: 'challenge',
        positionIndex: 4,
        keywordIds: [
          NarrativeKeywordIds.imbalance,
          NarrativeKeywordIds.confusion,
          NarrativeKeywordIds.isolation,
          NarrativeKeywordIds.abundance,
          NarrativeKeywordIds.intimacy,
        ],
        transforms: [ReversedTransformKind.delay, ReversedTransformKind.excess],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: celtic(),
        questionKind: QuestionKind.relationship,
      );
      expect(ev.breakdown.total, lessThanOrEqualTo(3.5));
      expect(ev.strength, inInclusiveRange(0.0, 1.0));
    });
  });

  group('pair normalization', () {
    test('lower positionIndex becomes left', () {
      final a = ctx(id: 'z', positionKey: 'future', positionIndex: 2);
      final b = ctx(id: 'a', positionKey: 'past', positionIndex: 0);
      final ev = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: threeCard(),
        questionKind: QuestionKind.open,
      );
      expect(ev.left.positionIndex, 0);
      expect(ev.right.positionIndex, 2);
    });
  });
}
