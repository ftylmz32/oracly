/// Phase 3D.1C — selector theme, ranking, evidence ids, edges inventory.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_keyword_discrimination.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_position_edges.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_scorer.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_selector.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';

import 'narrative_relationship_test_support.dart';

void main() {
  test(
    'authoritative edges: 29 inventory + at most one per unordered pair',
    () {
      expect(kAuthoritativePositionEdges, hasLength(29));
      expect(
        kAuthoritativePositionEdges
            .where((e) => e.edgeKind == PositionEdgeKind.temporal)
            .length,
        11,
      );
      expect(
        kAuthoritativePositionEdges
            .where((e) => e.edgeKind == PositionEdgeKind.pressure)
            .length,
        8,
      );
      expect(
        kAuthoritativePositionEdges
            .where((e) => e.edgeKind == PositionEdgeKind.opposition)
            .length,
        3,
      );
      expect(
        kAuthoritativePositionEdges
            .where((e) => e.edgeKind == PositionEdgeKind.supportive)
            .length,
        4,
      );
      expect(
        kAuthoritativePositionEdges
            .where((e) => e.edgeKind == PositionEdgeKind.mirror)
            .length,
        3,
      );

      final seen = <String>{};
      for (final e in kAuthoritativePositionEdges) {
        final a = e.fromPositionKey.compareTo(e.toPositionKey) <= 0
            ? e.fromPositionKey
            : e.toPositionKey;
        final b = e.fromPositionKey.compareTo(e.toPositionKey) <= 0
            ? e.toPositionKey
            : e.fromPositionKey;
        final key = '${e.legacyTypeName}|$a|$b';
        expect(seen.contains(key), isFalse, reason: 'duplicate edge $key');
        seen.add(key);
      }
    },
  );

  test('theme pair eligible: S_overlap>=2 with rare id; HF-only reject', () {
    // Build enough rare overlap to reach >=2.0
    final rares = [
      NarrativeKeywordIds.abundance,
      NarrativeKeywordIds.attachment,
      NarrativeKeywordIds.authority,
      NarrativeKeywordIds.awakening,
      NarrativeKeywordIds.bias,
    ];
    var predicted = 0.0;
    for (final id in rares) {
      predicted += NarrativeKeywordDiscrimination.weight(id) / 6.0;
    }
    expect(predicted, greaterThanOrEqualTo(2.0));

    final a = ctx(
      id: 'a',
      positionKey: 'self',
      positionIndex: 6,
      keywordIds: rares,
    );
    final b = ctx(
      id: 'b',
      positionKey: 'outcome',
      positionIndex: 9,
      keywordIds: rares,
    );
    final ev = NarrativeRelationshipScorer.evaluate(
      a: a,
      b: b,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(ev.themePairEligible, isTrue);

    final hf = ctx(
      id: 'c',
      positionKey: 'self',
      positionIndex: 6,
      keywordIds: [
        NarrativeKeywordIds.haste,
        NarrativeKeywordIds.scatter,
        NarrativeKeywordIds.escape,
        NarrativeKeywordIds.control,
        NarrativeKeywordIds.delay,
        NarrativeKeywordIds.fear,
        NarrativeKeywordIds.display,
      ],
    );
    final hf2 = ctx(
      id: 'd',
      positionKey: 'outcome',
      positionIndex: 9,
      keywordIds: [
        NarrativeKeywordIds.haste,
        NarrativeKeywordIds.scatter,
        NarrativeKeywordIds.escape,
        NarrativeKeywordIds.control,
        NarrativeKeywordIds.delay,
        NarrativeKeywordIds.fear,
        NarrativeKeywordIds.display,
      ],
    );
    final hfEv = NarrativeRelationshipScorer.evaluate(
      a: hf,
      b: hf2,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(hfEv.themePairEligible, isFalse);
  });

  test('three-card cluster + at most one themeRepetition', () {
    final id = NarrativeKeywordIds.abundance; // df=1 <=6
    final cards = [
      ctx(id: 'c0', positionKey: 'past', positionIndex: 0, keywordIds: [id]),
      ctx(id: 'c1', positionKey: 'present', positionIndex: 1, keywordIds: [id]),
      ctx(id: 'c2', positionKey: 'future', positionIndex: 2, keywordIds: [id]),
    ];
    // Pair alone may be causeEffect due to temporal — use celtic slots without
    // higher-priority kinds between non-edge pairs.
    final celticCards = [
      ctx(id: 'c0', positionKey: 'self', positionIndex: 6, keywordIds: [id]),
      ctx(id: 'c1', positionKey: 'outcome', positionIndex: 9, keywordIds: [id]),
      ctx(id: 'c2', positionKey: 'crown', positionIndex: 4, keywordIds: [id]),
    ];
    final out = NarrativeRelationshipSelector.select(
      cards: celticCards,
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    final themes = out
        .where((e) => e.kind == RelationshipKind.themeRepetition)
        .toList();
    expect(themes, hasLength(1));
    expect(themes.single.provenance.contains('themeEcho'), isTrue);

    // threeCard temporal will prefer causeEffect over theme
    final temporalOut = NarrativeRelationshipSelector.select(
      cards: cards,
      spread: threeCard(),
      questionKind: QuestionKind.open,
    );
    expect(
      temporalOut.any((e) => e.kind == RelationshipKind.causeEffect),
      isTrue,
    );
  });

  test('higher-priority contrast beats theme', () {
    final rares = [
      NarrativeKeywordIds.abundance,
      NarrativeKeywordIds.attachment,
      NarrativeKeywordIds.authority,
      NarrativeKeywordIds.awakening,
      NarrativeKeywordIds.bias,
      NarrativeKeywordIds.balance,
    ];
    final a = ctx(
      id: 'a',
      positionKey: 'self',
      positionIndex: 6,
      keywordIds: rares,
    );
    final b = ctx(
      id: 'b',
      positionKey: 'outcome',
      positionIndex: 9,
      keywordIds: [
        NarrativeKeywordIds.abundance,
        NarrativeKeywordIds.attachment,
        NarrativeKeywordIds.authority,
        NarrativeKeywordIds.awakening,
        NarrativeKeywordIds.bias,
        NarrativeKeywordIds.imbalance,
      ],
    );
    final out = NarrativeRelationshipSelector.select(
      cards: [a, b],
      spread: celtic(),
      questionKind: QuestionKind.open,
    );
    expect(out.single.kind, RelationshipKind.contrast);
  });

  test('top-N=12 with rel_## and input reorder independence', () {
    final cards = <dynamic>[];
    // 8 cards → C(8,2)=28 pairs; make many admit via rare+canonical
    final rare = NarrativeKeywordIds.abundance;
    final positions = celtic().positions;
    for (var i = 0; i < 8; i++) {
      final p = positions[i];
      final id = 'card_$i';
      final related = [
        for (var j = 0; j < 8; j++)
          if (j != i) 'card_$j',
      ];
      cards.add(
        ctx(
          id: id,
          positionKey: p.positionKey,
          positionIndex: p.index,
          keywordIds: [rare, NarrativeKeywordIds.attachment],
          relatedIds: related,
        ),
      );
    }

    final out1 = NarrativeRelationshipSelector.select(
      cards: List.from(cards),
      spread: celtic(),
      questionKind: QuestionKind.open,
      maxRelationships: 12,
    );
    final out2 = NarrativeRelationshipSelector.select(
      cards: List.from(cards.reversed),
      spread: celtic(),
      questionKind: QuestionKind.open,
      maxRelationships: 12,
    );
    expect(out1, hasLength(12));
    expect(out2, hasLength(12));
    for (var i = 0; i < 12; i++) {
      expect(out1[i].evidenceId, 'rel_${(i + 1).toString().padLeft(2, '0')}');
      expect(out1[i].leftCardId, out2[i].leftCardId);
      expect(out1[i].rightCardId, out2[i].rightCardId);
      expect(out1[i].kind, out2[i].kind);
      expect(out1[i].strength, out2[i].strength);
    }
    expect(8 * 7 ~/ 2, 28); // pairs generated bound
    expect(10 * 9 ~/ 2, 45); // max for 10 cards
  });
}
