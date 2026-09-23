/// Phase 3D.1C red-team — determinism + provenance stability.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_scorer.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_selector.dart';

import '../narrative_relationship_test_support.dart';

void main() {
  test('input order independence for scorer + selector', () {
    final a = ctx(
      id: 'z_card',
      positionKey: 'future',
      positionIndex: 2,
      keywordIds: [NarrativeKeywordIds.abundance],
      relatedIds: ['a_card'],
    );
    final b = ctx(
      id: 'a_card',
      positionKey: 'past',
      positionIndex: 0,
      keywordIds: [NarrativeKeywordIds.abundance],
    );
    final ev1 = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    final ev2 = NarrativeRelationshipScorer.evaluate(
      a: b,
      b: a,
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    expect(ev1.left.canonicalCardId, ev2.left.canonicalCardId);
    expect(ev1.right.canonicalCardId, ev2.right.canonicalCardId);
    expect(ev1.breakdown.total, ev2.breakdown.total);
    expect(ev1.provenanceTokens, ev2.provenanceTokens);

    final out1 = NarrativeRelationshipSelector.select(
      cards: [a, b],
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    final out2 = NarrativeRelationshipSelector.select(
      cards: [b, a],
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    expect(
      out1.map((e) => e.evidenceId).toList(),
      out2.map((e) => e.evidenceId).toList(),
    );
    expect(
      out1.map((e) => '${e.leftCardId}|${e.rightCardId}|${e.kind}').toList(),
      out2.map((e) => '${e.leftCardId}|${e.rightCardId}|${e.kind}').toList(),
    );
  });

  test('provenance tokens sorted unique pipe-joined', () {
    final a = ctx(
      id: 'a',
      positionKey: 'past',
      positionIndex: 0,
      isReversed: true,
      keywordIds: [NarrativeKeywordIds.balance, NarrativeKeywordIds.intimacy],
      symbolTags: [NarrativeKeywordIds.clarity],
      relatedIds: ['b'],
      transforms: [],
    );
    final b = ctx(
      id: 'b',
      positionKey: 'present',
      positionIndex: 1,
      isReversed: false,
      keywordIds: [NarrativeKeywordIds.imbalance, NarrativeKeywordIds.intimacy],
      symbolTags: [NarrativeKeywordIds.clarity],
      relatedIds: [],
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: threeCard(),
      questionKind: QuestionKind.relationship,
    );
    final tokens = ev.provenanceTokens;
    expect(tokens.toSet().length, tokens.length);
    expect(tokens, List.of(tokens)..sort());
    expect(tokens, contains('keywordOverlap'));
    expect(tokens, contains('keywordContrast'));
    expect(tokens, contains('canonicalRelation'));
    expect(tokens, contains('positionEdge'));
    expect(tokens, contains('questionRelevance'));
    expect(tokens, contains('orientationPair'));
    expect(tokens, contains('symbolTag'));

    final out = NarrativeRelationshipSelector.select(
      cards: [a, b],
      spread: threeCard(),
      questionKind: QuestionKind.relationship,
    );
    final parts = out.single.provenance.split('|');
    expect(parts, List.of(parts)..sort());
    expect(out.single.noteKeyOrText, isNull);
  });

  test('theme input reorder picks same pair', () {
    final id = NarrativeKeywordIds.abundance;
    final cards = [
      ctx(id: 'c0', positionKey: 'self', positionIndex: 6, keywordIds: [id]),
      ctx(id: 'c1', positionKey: 'outcome', positionIndex: 9, keywordIds: [id]),
      ctx(id: 'c2', positionKey: 'crown', positionIndex: 4, keywordIds: [id]),
    ];
    final out1 = NarrativeRelationshipSelector.select(
      cards: cards,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    final out2 = NarrativeRelationshipSelector.select(
      cards: cards.reversed.toList(),
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    final t1 = out1.where((e) => e.kind.name == 'themeRepetition').toList();
    final t2 = out2.where((e) => e.kind.name == 'themeRepetition').toList();
    expect(t1, hasLength(1));
    expect(t2, hasLength(1));
    expect(t1.single.leftCardId, t2.single.leftCardId);
    expect(t1.single.rightCardId, t2.single.rightCardId);
  });
}
