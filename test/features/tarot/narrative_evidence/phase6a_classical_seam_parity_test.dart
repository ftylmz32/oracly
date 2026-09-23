/// Phase 6A — Classical resolver/edge provider/pairing/scorer/selector parity.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_position_edge_provider.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_position_edges.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_pairing.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_context.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_scorer.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_selector.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantic_resolver.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';

import 'narrative_evidence_test_support.dart';
import 'narrative_relationship_test_support.dart';

const _classical = <TarotSpreadType>[
  TarotSpreadType.single,
  TarotSpreadType.threeCard,
  TarotSpreadType.fiveCard,
  TarotSpreadType.sevenCard,
  TarotSpreadType.celticCross,
];

List<AuthoritativePositionEdge> _legacyFilter(String legacy) => [
  for (final e in kAuthoritativePositionEdges)
    if (e.legacyTypeName == legacy) e,
];

void _expectMatchEqual(
  NarrativePositionPairMatch a,
  NarrativePositionPairMatch b,
) {
  expect(a.edgeKind, b.edgeKind);
  expect(a.directed, b.directed);
  expect(a.fromPositionKey, b.fromPositionKey);
  expect(a.toPositionKey, b.toPositionKey);
  expect(a.leftRole, b.leftRole);
  expect(a.rightRole, b.rightRole);
}

void _expectEvalEqual(dynamic a, dynamic b) {
  expect(a.left.canonicalCardId, b.left.canonicalCardId);
  expect(a.right.canonicalCardId, b.right.canonicalCardId);
  expect(a.breakdown.total, b.breakdown.total);
  expect(a.breakdown.overlap, b.breakdown.overlap);
  expect(a.breakdown.contrast, b.breakdown.contrast);
  expect(a.breakdown.transform, b.breakdown.transform);
  expect(a.breakdown.canonical, b.breakdown.canonical);
  expect(a.breakdown.position, b.breakdown.position);
  expect(a.breakdown.question, b.breakdown.question);
  expect(a.sharedSemanticIds, b.sharedSemanticIds);
  expect(a.contrastClass, b.contrastClass);
  expect(a.effectiveSharedTransforms, b.effectiveSharedTransforms);
  expect(a.canonicalRelated, b.canonicalRelated);
  expect(a.positionEdgeKind, b.positionEdgeKind);
  expect(a.questionRelevant, b.questionRelevant);
  expect(a.independentFamilyCount, b.independentFamilyCount);
  expect(a.standardPath, b.standardPath);
  expect(a.canonicalPath, b.canonicalPath);
  expect(a.positionStrongPath, b.positionStrongPath);
  expect(a.normalAdmitted, b.normalAdmitted);
  expect(a.pageSuitGuard, b.pageSuitGuard);
  expect(a.courtRankGuard, b.courtRankGuard);
  expect(a.themePairEligible, b.themePairEligible);
  expect(a.higherPriorityKind, b.higherPriorityKind);
  expect(a.provenanceTokens, b.provenanceTokens);
  expect(a.strength, b.strength);
}

void main() {
  const resolver = ClassicalSpreadSemanticResolver();
  const provider = ClassicalPositionEdgeProvider();

  group('Classical resolver parity', () {
    test('exact identity with ClassicalSpreadSemantics', () {
      for (final type in _classical) {
        final old = ClassicalSpreadSemantics.byLegacyTypeName(type.name);
        final neu = resolver.resolve(type);
        expect(identical(old, neu), isTrue, reason: type.name);
        expect(neu.spreadId, old.spreadId);
        expect(neu.legacyTypeName, old.legacyTypeName);
        expect(neu.cardCount, old.cardCount);
        expect(neu.purposeKey, old.purposeKey);
        expect(neu.positions, old.positions);
        expect(neu.interpretationOrder, old.interpretationOrder);
        expect(neu.geometryHook, old.geometryHook);
        expect(neu.lengthBand, old.lengthBand);
      }
    });

    test('Crossroads fails closed', () {
      expect(
        () => resolver.resolve(TarotSpreadType.crossroads),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Classical edge provider parity', () {
    test('counts + order match filtered global table', () {
      expect(kAuthoritativePositionEdges, hasLength(29));
      final expected = {
        'single': 0,
        'threeCard': 3,
        'fiveCard': 6,
        'sevenCard': 8,
        'celticCross': 12,
      };
      for (final type in _classical) {
        final spread = ClassicalSpreadSemantics.byLegacyTypeName(type.name);
        final fromProvider = provider.edgesFor(spread);
        final legacy = _legacyFilter(type.name);
        expect(fromProvider, hasLength(expected[type.name]!));
        expect(fromProvider, hasLength(legacy.length));
        for (var i = 0; i < legacy.length; i++) {
          expect(fromProvider[i].legacyTypeName, legacy[i].legacyTypeName);
          expect(fromProvider[i].fromPositionKey, legacy[i].fromPositionKey);
          expect(fromProvider[i].toPositionKey, legacy[i].toPositionKey);
          expect(fromProvider[i].directed, legacy[i].directed);
          expect(fromProvider[i].edgeKind, legacy[i].edgeKind);
        }
      }
    });

    test('returned list is unmodifiable + deterministic', () {
      final spread = ClassicalSpreadSemantics.byLegacyTypeName('threeCard');
      final a = provider.edgesFor(spread);
      final b = provider.edgesFor(spread);
      expect(
        () => a.add(
          const AuthoritativePositionEdge(
            legacyTypeName: 'x',
            fromPositionKey: 'a',
            toPositionKey: 'b',
            directed: false,
            edgeKind: PositionEdgeKind.mirror,
          ),
        ),
        throwsUnsupportedError,
      );
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].fromPositionKey, b[i].fromPositionKey);
        expect(a[i].toPositionKey, b[i].toPositionKey);
      }
    });
  });

  group('pairing / scorer / selector parity', () {
    test('pairing default == explicit Classical == legacy scan', () {
      final spread = ClassicalSpreadSemantics.byLegacyTypeName('threeCard');
      final past = ctx(id: 'a', positionKey: 'past', positionIndex: 0);
      final present = ctx(id: 'b', positionKey: 'present', positionIndex: 1);
      final future = ctx(id: 'c', positionKey: 'future', positionIndex: 2);

      // Directed forward
      final d1 = NarrativeRelationshipPairing.matchPositions(
        spread: spread,
        left: past,
        right: present,
      );
      final d2 = NarrativeRelationshipPairing.matchPositions(
        spread: spread,
        left: past,
        right: present,
        edgeProvider: provider,
      );
      expect(d1.edgeKind, PositionEdgeKind.temporal);
      expect(d1.directed, isTrue);
      expect(d1.fromPositionKey, 'past');
      expect(d1.toPositionKey, 'present');
      _expectMatchEqual(d1, d2);

      // Directed reversed caller order — authoritative direction preserved
      final rev = NarrativeRelationshipPairing.matchPositions(
        spread: spread,
        left: present,
        right: past,
        edgeProvider: provider,
      );
      expect(rev.fromPositionKey, 'past');
      expect(rev.toPositionKey, 'present');
      expect(rev.directed, isTrue);

      // No-edge pair (single has none; threeCard past/future HAS edge —
      // use fiveCard non-adjacent no-edge: hidden_influence / strength)
      final five = ClassicalSpreadSemantics.byLegacyTypeName('fiveCard');
      final hi = ctx(
        id: 'h',
        positionKey: 'hidden_influence',
        positionIndex: 3,
      );
      final st = ctx(id: 's', positionKey: 'strength', positionIndex: 2);
      final none = NarrativeRelationshipPairing.matchPositions(
        spread: five,
        left: hi,
        right: st,
        edgeProvider: provider,
      );
      expect(none.edgeKind, isNull);

      // Undirected fiveCard
      final sit = ctx(id: 'sit', positionKey: 'situation', positionIndex: 0);
      final ch = ctx(id: 'ch', positionKey: 'challenge', positionIndex: 1);
      final und = NarrativeRelationshipPairing.matchPositions(
        spread: five,
        left: sit,
        right: ch,
        edgeProvider: provider,
      );
      expect(und.edgeKind, PositionEdgeKind.opposition);
      expect(und.directed, isFalse);

      // future unused in directed tests above — keep analyzer quiet
      expect(future.positionKey, 'future');
    });

    test('scorer default == explicit Classical provider', () {
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
      final def = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: threeCard(),
        questionKind: QuestionKind.open,
      );
      final exp = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: threeCard(),
        questionKind: QuestionKind.open,
        edgeProvider: provider,
      );
      _expectEvalEqual(def, exp);
    });

    test('selector default == explicit Classical provider', () {
      final cards = [
        ctx(
          id: 'a',
          positionKey: 'past',
          positionIndex: 0,
          keywordIds: [
            NarrativeKeywordIds.abundance,
            NarrativeKeywordIds.attachment,
          ],
        ),
        ctx(
          id: 'b',
          positionKey: 'present',
          positionIndex: 1,
          keywordIds: [
            NarrativeKeywordIds.abundance,
            NarrativeKeywordIds.attachment,
          ],
        ),
        ctx(
          id: 'c',
          positionKey: 'future',
          positionIndex: 2,
          keywordIds: [NarrativeKeywordIds.haste],
        ),
      ];
      final def = NarrativeRelationshipSelector.select(
        cards: cards,
        spread: threeCard(),
        questionKind: QuestionKind.open,
      );
      final exp = NarrativeRelationshipSelector.select(
        cards: cards,
        spread: threeCard(),
        questionKind: QuestionKind.open,
        edgeProvider: provider,
      );
      expect(def.length, exp.length);
      for (var i = 0; i < def.length; i++) {
        expect(def[i].evidenceId, exp[i].evidenceId);
        expect(def[i].leftCardId, exp[i].leftCardId);
        expect(def[i].rightCardId, exp[i].rightCardId);
        expect(def[i].leftPositionKey, exp[i].leftPositionKey);
        expect(def[i].rightPositionKey, exp[i].rightPositionKey);
        expect(def[i].kind, exp[i].kind);
        expect(def[i].provenance, exp[i].provenance);
        expect(def[i].strength, exp[i].strength);
      }
    });
  });

  group('frozen corpus smoke + Crossroads firewall', () {
    test('default builder still builds first classical corpus scenario', () {
      final corpus = loadEvidenceCorpus();
      final scenarios =
          (corpus['scenarios'] as List).cast<Map<String, dynamic>>();
      final s = scenarios.first;
      final expected = s['expected'] as Map<String, dynamic>;
      final req = NarrativeEvidenceBuilder.build(inputFromScenario(s));
      expect(req.spread.spreadId, expected['spreadId']);
      expect(req.cards, hasLength(expected['cardCount'] as int));
    });

    test('default builder Crossroads still fails closed', () {
      expect(
        () => NarrativeEvidenceBuilder.build(
          inputFromScenario({
            'input': {
              'sessionId': 'sess-cr',
              'readingId': 'read-cr',
              'languageCode': 'en',
              'spreadType': 'crossroads',
              'cards': [
                for (var i = 0; i < 5; i++)
                  {
                    'canonicalCardId': 'major_0$i',
                    'ritualCardId': i,
                    'isReversed': false,
                    'positionKey': 'situation',
                    'positionIndex': i,
                  },
              ],
            },
          }),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('unknown classical spread'),
          ),
        ),
      );
    });
  });
}
