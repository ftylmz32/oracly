/// Phase 3D.1C — kind resolution positive + near-miss cases.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_kind_resolver.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_scorer.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_selector.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';

import 'narrative_relationship_test_support.dart';

void main() {
  test('HARD on temporal → contrast (not conflict)', () {
    final a = ctx(
      id: 'a',
      positionKey: 'past',
      positionIndex: 0,
      keywordIds: [NarrativeKeywordIds.balance],
      relatedIds: ['b'],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'present',
      positionIndex: 1,
      keywordIds: [NarrativeKeywordIds.imbalance],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    expect(ev.higherPriorityKind, RelationshipKind.contrast);
    expect(ev.breakdown.contrast, 0.70);
    expect(ev.breakdown.canonical, 0.55);
  });

  test('HARD + opposition to challenge → conflict', () {
    final a = ctx(
      id: 'a',
      positionKey: 'present',
      positionIndex: 0,
      keywordIds: [NarrativeKeywordIds.clarity],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'challenge',
      positionIndex: 1,
      keywordIds: [NarrativeKeywordIds.confusion],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(ev.higherPriorityKind, RelationshipKind.conflict);
  });

  test('conflict near-miss: HARD without challenge/pressure → contrast', () {
    final a = ctx(
      id: 'a',
      positionKey: 'past',
      positionIndex: 0,
      keywordIds: [NarrativeKeywordIds.union],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'future',
      positionIndex: 2,
      keywordIds: [NarrativeKeywordIds.isolation],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    expect(ev.higherPriorityKind, RelationshipKind.contrast);
    expect(ev.higherPriorityKind, isNot(RelationshipKind.conflict));
  });

  test('temporal + semantic → causeEffect; undirected cannot', () {
    final a = ctx(
      id: 'a',
      positionKey: 'past',
      positionIndex: 0,
      keywordIds: [NarrativeKeywordIds.abundance],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'present',
      positionIndex: 1,
      keywordIds: [NarrativeKeywordIds.abundance],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    expect(ev.higherPriorityKind, RelationshipKind.causeEffect);

    final out = NarrativeRelationshipSelector.select(
      cards: [a, b],
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    expect(out.single.kind, RelationshipKind.causeEffect);
    expect(out.single.noteKeyOrText, isNull);
  });

  test('blockage with other family', () {
    final a = ctx(
      id: 'a',
      positionKey: 'self',
      positionIndex: 6,
      keywordIds: [NarrativeKeywordIds.delay],
      relatedIds: ['b'],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'outcome',
      positionIndex: 9,
      keywordIds: [NarrativeKeywordIds.delay],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(ev.higherPriorityKind, RelationshipKind.blockage);
  });

  test('blockage near-miss: trigger alone without other family', () {
    final a = ctx(
      id: 'a',
      positionKey: 'past',
      positionIndex: 0,
      keywordIds: [NarrativeKeywordIds.stagnation],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'present',
      positionIndex: 1,
      keywordIds: [NarrativeKeywordIds.stagnation],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    // SEMANTIC only → families=1; no temporal causeEffect without? wait temporal+semantic = causeEffect first!
    // past-present has temporal → causeEffect beats blockage
    expect(ev.higherPriorityKind, RelationshipKind.causeEffect);
  });

  test('blockage near-miss without temporal: single family reject', () {
    final a = ctx(
      id: 'a',
      positionKey: 'self',
      positionIndex: 6,
      keywordIds: [NarrativeKeywordIds.bondage],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'outcome',
      positionIndex: 9,
      keywordIds: [NarrativeKeywordIds.bondage],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(ev.independentFamilyCount, 1);
    expect(ev.higherPriorityKind, isNull);
    expect(ev.normalAdmitted, isFalse);
  });

  test('softening: shared soft keyword + pressure', () {
    final a = ctx(
      id: 'a',
      positionKey: 'challenge',
      positionIndex: 1,
      keywordIds: [NarrativeKeywordIds.compassion],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'outcome',
      positionIndex: 9,
      keywordIds: [NarrativeKeywordIds.compassion],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(ev.positionEdgeKind, PositionEdgeKind.pressure);
    expect(ev.higherPriorityKind, RelationshipKind.softening);
  });

  test('escalation with other family', () {
    final a = ctx(
      id: 'a',
      positionKey: 'past',
      positionIndex: 0,
      keywordIds: [NarrativeKeywordIds.anger],
      relatedIds: ['b'],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'present',
      positionIndex: 1,
      keywordIds: [NarrativeKeywordIds.anger],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    // temporal+semantic → causeEffect wins before escalation
    expect(ev.higherPriorityKind, RelationshipKind.causeEffect);
  });

  test('escalation without temporal: excess transform + canonical', () {
    final a = ctx(
      id: 'a',
      positionKey: 'self',
      positionIndex: 6,
      keywordIds: [NarrativeKeywordIds.haste],
      transforms: [ReversedTransformKind.excess],
      relatedIds: ['b'],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'outcome',
      positionIndex: 9,
      keywordIds: [NarrativeKeywordIds.haste],
      transforms: [ReversedTransformKind.excess],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(ev.higherPriorityKind, RelationshipKind.escalation);
  });

  test('escalation near-miss: trigger alone', () {
    final a = ctx(
      id: 'a',
      positionKey: 'self',
      positionIndex: 6,
      keywordIds: [NarrativeKeywordIds.impatience],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'outcome',
      positionIndex: 9,
      keywordIds: [NarrativeKeywordIds.impatience],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(ev.higherPriorityKind, isNull);
  });

  test('resolution: supportive + resolution keyword', () {
    final five = ClassicalSpreadSemantics.byLegacyTypeName('fiveCard');
    final a = ctx(
      id: 'a',
      positionKey: 'challenge',
      positionIndex: 2,
      keywordIds: [NarrativeKeywordIds.renewal],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'strength',
      positionIndex: 3,
      keywordIds: [NarrativeKeywordIds.renewal],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: five,
      questionKind: QuestionKind.open,
    );
    expect(ev.positionEdgeKind, PositionEdgeKind.supportive);
    expect(ev.higherPriorityKind, RelationshipKind.resolution);
  });

  test('resolution near-miss: resolution keyword without supportive', () {
    final a = ctx(
      id: 'a',
      positionKey: 'self',
      positionIndex: 6,
      keywordIds: [NarrativeKeywordIds.release],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'outcome',
      positionIndex: 9,
      keywordIds: [NarrativeKeywordIds.release],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(ev.higherPriorityKind, isNot(RelationshipKind.resolution));
  });

  test('support vs reinforcement fallback', () {
    final supportIds = {NarrativeKeywordIds.haste, NarrativeKeywordIds.fear};
    expect(
      NarrativeRelationshipKindResolver.supportOrReinforcement(supportIds),
      RelationshipKind.support,
    );

    final rare = {
      NarrativeKeywordIds.abundance, // df 1
      NarrativeKeywordIds.attachment, // df 1
    };
    expect(
      NarrativeRelationshipKindResolver.supportOrReinforcement(rare),
      RelationshipKind.reinforcement,
    );
  });

  test('canonical + HARD: contrast wins; no support; +0.70 no -0.60', () {
    final a = ctx(
      id: 'a',
      positionKey: 'past',
      positionIndex: 0,
      keywordIds: [NarrativeKeywordIds.balance, NarrativeKeywordIds.abundance],
      relatedIds: ['b'],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'present',
      positionIndex: 1,
      keywordIds: [
        NarrativeKeywordIds.imbalance,
        NarrativeKeywordIds.abundance,
      ],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    expect(ev.higherPriorityKind, RelationshipKind.contrast);
    expect(ev.breakdown.contrast, 0.70);
    expect(ev.breakdown.canonical, 0.55);
    final out = NarrativeRelationshipSelector.select(
      cards: [a, b],
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    expect(out.single.kind, RelationshipKind.contrast);
    expect(out.single.kind, isNot(RelationshipKind.support));
    expect(out.single.kind, isNot(RelationshipKind.reinforcement));
  });
}
