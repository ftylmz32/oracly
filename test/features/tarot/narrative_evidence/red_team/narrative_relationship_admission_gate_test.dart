/// Phase 3D.1C.1 — non-theme kinds require normalAdmitted; theme exception.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_scorer.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_selector.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';

import '../narrative_relationship_test_support.dart';

void main() {
  test('A HARD contrast only: higherPriority=contrast, selector EMPTY', () {
    final a = ctx(
      id: 'a',
      positionKey: 'self',
      positionIndex: 6,
      keywordIds: [NarrativeKeywordIds.balance],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'outcome',
      positionIndex: 9,
      keywordIds: [NarrativeKeywordIds.imbalance],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(ev.higherPriorityKind, RelationshipKind.contrast);
    expect(ev.normalAdmitted, isFalse);
    expect(ev.breakdown.contrast, 0.70);
    final out = NarrativeRelationshipSelector.select(
      cards: [a, b],
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(out, isEmpty);
  });

  test('B CONTEXTUAL contrast only: selector EMPTY', () {
    final a = ctx(
      id: 'a',
      positionKey: 'self',
      positionIndex: 6,
      keywordIds: [NarrativeKeywordIds.momentum],
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
    expect(ev.breakdown.contrast, 0.45);
    expect(ev.normalAdmitted, isFalse);
    final out = NarrativeRelationshipSelector.select(
      cards: [a, b],
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(out, isEmpty);
  });

  test('C weak temporal + HF: causeEffect classified, selector EMPTY', () {
    final a = ctx(
      id: 'a',
      positionKey: 'past',
      positionIndex: 0,
      keywordIds: [NarrativeKeywordIds.haste],
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
    expect(ev.higherPriorityKind, RelationshipKind.causeEffect);
    expect(ev.breakdown.total, lessThan(1.0));
    expect(ev.normalAdmitted, isFalse);
    final out = NarrativeRelationshipSelector.select(
      cards: [a, b],
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    expect(out, isEmpty);
  });

  test('D weak softening: classified but not admitted → EMPTY', () {
    final five = ClassicalSpreadSemantics.byLegacyTypeName('fiveCard');
    // pause (df=7) + supportive 0.30 → S≈0.96 < 1.0
    final a = ctx(
      id: 'a',
      positionKey: 'challenge',
      positionIndex: 2,
      keywordIds: [NarrativeKeywordIds.pause],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'strength',
      positionIndex: 3,
      keywordIds: [NarrativeKeywordIds.pause],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: five,
      questionKind: QuestionKind.open,
    );
    expect(ev.higherPriorityKind, RelationshipKind.softening);
    expect(ev.positionEdgeKind, PositionEdgeKind.supportive);
    expect(ev.breakdown.total, lessThan(1.0));
    expect(ev.normalAdmitted, isFalse);
    final out = NarrativeRelationshipSelector.select(
      cards: [a, b],
      spread: five,
      questionKind: QuestionKind.open,
    );
    expect(out, isEmpty);
  });

  test('E weak resolution: classified but not admitted → EMPTY', () {
    final five = ClassicalSpreadSemantics.byLegacyTypeName('fiveCard');
    // opening (df=6) + supportive 0.30 → S < 1.0
    final a = ctx(
      id: 'a',
      positionKey: 'challenge',
      positionIndex: 2,
      keywordIds: [NarrativeKeywordIds.opening],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'strength',
      positionIndex: 3,
      keywordIds: [NarrativeKeywordIds.opening],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: five,
      questionKind: QuestionKind.open,
    );
    expect(ev.higherPriorityKind, RelationshipKind.resolution);
    expect(ev.breakdown.total, lessThan(1.0));
    expect(ev.normalAdmitted, isFalse);
    final out = NarrativeRelationshipSelector.select(
      cards: [a, b],
      spread: five,
      questionKind: QuestionKind.open,
    );
    expect(out, isEmpty);
  });

  test('F valid admitted contrast: EMITTED', () {
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
    expect(ev.normalAdmitted, isTrue);
    final out = NarrativeRelationshipSelector.select(
      cards: [a, b],
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    expect(out, hasLength(1));
    expect(out.single.kind, RelationshipKind.contrast);
  });

  test('theme special admission when normalAdmitted=false', () {
    final id = NarrativeKeywordIds.abundance; // df=1
    final cards = [
      ctx(id: 'c0', positionKey: 'self', positionIndex: 6, keywordIds: [id]),
      ctx(id: 'c1', positionKey: 'outcome', positionIndex: 9, keywordIds: [id]),
      ctx(id: 'c2', positionKey: 'crown', positionIndex: 4, keywordIds: [id]),
    ];
    // Pair alone: SEMANTIC only → not normalAdmitted
    final pair = NarrativeRelationshipScorer.evaluate(
      a: cards[0],
      b: cards[1],
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(pair.normalAdmitted, isFalse);

    final out = NarrativeRelationshipSelector.select(
      cards: cards,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    final themes = out
        .where((e) => e.kind == RelationshipKind.themeRepetition)
        .toList();
    expect(themes, hasLength(1));
  });
}
