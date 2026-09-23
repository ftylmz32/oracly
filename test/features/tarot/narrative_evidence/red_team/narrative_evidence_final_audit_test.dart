/// Phase 3D.1E — independent Evidence Engine final audit (test-only).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_enums.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_error.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_input.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_keyword_contrasts.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_keyword_discrimination.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_position_edges.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_profile_slice.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_context.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_guards.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_rules.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_scorer.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_selector.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_semantic_channel.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';

import '../narrative_evidence_test_support.dart';
import '../narrative_relationship_test_support.dart';

void main() {
  group('3D.1E bridge / catalog integrity', () {
    test('78 deck ids unique and match expectedIds', () {
      final ids = OraclyTarotDeck.expectedIds;
      expect(ids.length, 78);
      expect(ids.toSet().length, 78);
      for (final id in ids) {
        expect(OraclyTarotDeck.byId(id), isNotNull);
      }
    });

    test('ritual 0..77 resolve uniquely to full deck', () {
      final resolved = <String>{};
      for (var i = 0; i < 78; i++) {
        final card = OraclyTarotBridge.byRitualId(i);
        expect(card, isNotNull, reason: 'ritual $i');
        expect(resolved.add(card!.id), isTrue, reason: 'dup ${card.id}');
      }
      expect(resolved, OraclyTarotDeck.expectedIds.toSet());
      expect(OraclyTarotBridge.byRitualId(-1), isNull);
      expect(OraclyTarotBridge.byRitualId(78), isNull);
      expect(OraclyTarotBridge.byRitualId(999), isNull);
    });

    test('78 profiles ↔ deck bijective', () {
      expect(NarrativeTarotProfileCatalog.count, 78);
      for (final id in OraclyTarotDeck.expectedIds) {
        expect(NarrativeTarotProfileCatalog.lookup(id), isNotNull);
      }
    });
  });

  group('3D.1E 156 orientation integrity', () {
    test('every upright/reversed orientation builds channel', () {
      var ok = 0;
      for (final id in OraclyTarotDeck.expectedIds) {
        final profile = NarrativeTarotProfileCatalog.lookup(id)!;
        for (final rev in [false, true]) {
          final slice = TarotNarrativeProfileSlice.fromProfile(
            profile,
            isReversed: rev,
            questionKind: QuestionKind.open,
          );
          final channel = NarrativeSemanticChannel.from(
            keywordIds: slice.keywordIds,
            symbolTags: slice.symbolTags,
          );
          expect(
            channel.semanticIds.toSet().length,
            channel.semanticIds.length,
          );
          if (!rev) {
            expect(slice.transforms, isEmpty);
          }
          ok++;
        }
      }
      expect(ok, 156);
    });
  });

  group('3D.1E signal layer constants', () {
    test('discrimination + contrasts + transforms match locked metrics', () {
      expect(NarrativeKeywordDiscrimination.ontologyRevision, 1);
      expect(NarrativeKeywordDiscrimination.orientationCount, 156);
      expect(NarrativeKeywordDiscrimination.documentFrequency.length, 128);
      expect(NarrativeKeywordDiscrimination.df('scatter'), 14);
      expect(NarrativeKeywordDiscrimination.df('haste'), 13);
      expect(NarrativeKeywordDiscrimination.highFrequencyDfThreshold, 8);

      expect(NarrativeKeywordContrasts.hardPairCount, 11);
      expect(NarrativeKeywordContrasts.contextualPairCount, 4);
      expect(NarrativeKeywordContrasts.totalPairCount, 15);

      var kwTagOverlapOri = 0;
      final transformCounts = <ReversedTransformKind, int>{
        for (final k in ReversedTransformKind.values) k: 0,
      };
      for (final id in OraclyTarotDeck.expectedIds) {
        final profile = NarrativeTarotProfileCatalog.lookup(id)!;
        for (final rev in [false, true]) {
          final slice = TarotNarrativeProfileSlice.fromProfile(
            profile,
            isReversed: rev,
            questionKind: QuestionKind.open,
          );
          final kw = slice.keywordIds.toSet();
          final tags = slice.symbolTags.toSet();
          if (kw.intersection(tags).isNotEmpty) kwTagOverlapOri++;
          for (final t in slice.transforms) {
            transformCounts[t] = transformCounts[t]! + 1;
          }
        }
      }
      expect(kwTagOverlapOri, 64);
      expect(transformCounts[ReversedTransformKind.excess], 37);
      expect(transformCounts[ReversedTransformKind.distortion], 23);
      expect(transformCounts[ReversedTransformKind.misdirection], 18);
      expect(transformCounts[ReversedTransformKind.avoidance], 17);
      expect(transformCounts[ReversedTransformKind.internalization], 15);
      expect(transformCounts[ReversedTransformKind.delay], 14);
      expect(transformCounts[ReversedTransformKind.blockedExpression], 14);
      expect(transformCounts[ReversedTransformKind.deficiency], 9);
      expect(transformCounts[ReversedTransformKind.privateInternal], 8);
      expect(transformCounts[ReversedTransformKind.release], 1);
    });

    test('scoring / admission / FR constants exact', () {
      expect(NarrativeRelationshipRules.hardContrast, 0.70);
      expect(NarrativeRelationshipRules.contextualContrast, 0.45);
      expect(NarrativeRelationshipRules.transformEach, 0.15);
      expect(NarrativeRelationshipRules.transformCap, 0.30);
      expect(NarrativeRelationshipRules.canonicalBonus, 0.55);
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
      expect(NarrativeRelationshipRules.frOverlapCap, 0.35);
      expect(NarrativeRelationshipRules.frStrengthCap, 0.45);
      expect(NarrativeRelationshipRules.themeOverlapMin, 2.0);
      expect(NarrativeRelationshipRules.scoreClampMax, 3.5);
      expect(NarrativeRelationshipRules.maxRelationshipsDefault, 12);
    });
  });

  group('3D.1E spread / edge catalog', () {
    test('5 spreads · 26 positions · 29 edges · kinds', () {
      final spreads = [
        'single',
        'threeCard',
        'fiveCard',
        'sevenCard',
        'celticCross',
      ];
      var positions = 0;
      for (final name in spreads) {
        positions += ClassicalSpreadSemantics.byLegacyTypeName(
          name,
        ).positions.length;
      }
      expect(spreads.length, 5);
      expect(positions, 26);

      final edges = kAuthoritativePositionEdges;
      expect(edges.length, 29);
      final directed = edges.where((e) => e.directed).length;
      final undirected = edges.length - directed;
      expect(directed, 13);
      expect(undirected, 16);
      expect(directed + undirected * 2, 45);

      final kinds = <PositionEdgeKind, int>{};
      for (final e in edges) {
        kinds[e.edgeKind] = (kinds[e.edgeKind] ?? 0) + 1;
      }
      expect(kinds[PositionEdgeKind.temporal], 11);
      expect(kinds[PositionEdgeKind.pressure], 8);
      expect(kinds[PositionEdgeKind.opposition], 3);
      expect(kinds[PositionEdgeKind.supportive], 4);
      expect(kinds[PositionEdgeKind.mirror], 3);
    });
  });

  group('3D.1E FR + Major court false positives', () {
    test('FR-F01 pageSuitGuard true for wands_11↑×pentacles_11↑', () {
      final a = _ctxFromDeck('wands_11', false, 'self', 6);
      final b = _ctxFromDeck('pentacles_11', false, 'outcome', 9);
      // Strip canonical relations for identity-only admission check.
      final aId = NarrativeRelationshipCardContext(
        canonicalCardId: a.canonicalCardId,
        positionKey: a.positionKey,
        positionIndex: a.positionIndex,
        isReversed: a.isReversed,
        suit: a.suit,
        number: a.number,
        keywordIds: a.keywordIds,
        semanticChannel: a.semanticChannel,
        transforms: a.transforms,
        relatedIds: const [],
      );
      final bId = NarrativeRelationshipCardContext(
        canonicalCardId: b.canonicalCardId,
        positionKey: b.positionKey,
        positionIndex: b.positionIndex,
        isReversed: b.isReversed,
        suit: b.suit,
        number: b.number,
        keywordIds: b.keywordIds,
        semanticChannel: b.semanticChannel,
        transforms: b.transforms,
        relatedIds: const [],
      );
      expect(aId.keywordIds.toSet(), bId.keywordIds.toSet());
      expect(NarrativeRelationshipGuards.pageSuitGuard(aId, bId), isTrue);
      final identity = NarrativeRelationshipScorer.evaluate(
        a: aId,
        b: bId,
        spread: celtic(),
        questionKind: QuestionKind.open,
      );
      expect(identity.normalAdmitted, isFalse);
    });

    test('FR-F02 courtRankGuard true for swords_11↓×swords_12↓', () {
      final a = _ctxFromDeck('swords_11', true, 'past', 0);
      final b = _ctxFromDeck('swords_12', true, 'present', 1);
      expect(a.keywordIds.toSet(), b.keywordIds.toSet());
      expect(NarrativeRelationshipGuards.courtRankGuard(a, b), isTrue);
    });

    test('Major numbers 11–14 never trip court guards', () {
      for (final n in [11, 12, 13, 14]) {
        final major = _ctxFromDeck(
          'major_${n.toString().padLeft(2, '0')}',
          false,
          'past',
          0,
        );
        final page = _ctxFromDeck('cups_11', false, 'present', 1);
        final knight = _ctxFromDeck('cups_12', false, 'future', 2);
        expect(NarrativeRelationshipGuards.pageSuitGuard(major, page), isFalse);
        expect(
          NarrativeRelationshipGuards.courtRankGuard(major, knight),
          isFalse,
        );
      }
    });
  });

  group('3D.1E admission / theme / bounds', () {
    test('HARD contrast only REJECT; theme may admit without normal', () {
      // celtic self↔outcome has no authoritative edge → contrast family alone.
      final hardOnly = ctx(
        id: 'a',
        positionKey: 'self',
        positionIndex: 6,
        keywordIds: const ['balance'],
      );
      final hardOther = ctx(
        id: 'b',
        positionKey: 'outcome',
        positionIndex: 9,
        keywordIds: const ['imbalance'],
      );
      final ev = NarrativeRelationshipScorer.evaluate(
        a: hardOnly,
        b: hardOther,
        spread: celtic(),
        questionKind: QuestionKind.open,
      );
      expect(ev.contrastClass, NarrativeKeywordContrastClass.hard);
      expect(ev.normalAdmitted, isFalse);

      final spread = threeCard();
      final cards = <NarrativeRelationshipCardContext>[
        for (final p in spread.positions)
          ctx(
            id: 'c${p.index}',
            positionKey: p.positionKey,
            positionIndex: p.index,
            keywordIds: const ['clarity', 'focus', 'truth'],
            symbolTags: const ['clarity', 'focus', 'truth'],
          ),
      ];
      final selected = NarrativeRelationshipSelector.select(
        cards: cards,
        spread: spread,
        questionKind: QuestionKind.open,
        maxRelationships: 12,
      );
      expect(selected.length, lessThanOrEqualTo(12));
    });

    test('maxRelationships clamp + 11 cards typed fail', () {
      final spread = celtic();
      final cards = <NarrativeRelationshipCardContext>[
        for (final p in spread.positions)
          _ctxFromDeck(
            OraclyTarotDeck.expectedIds[p.index],
            false,
            p.positionKey,
            p.index,
          ),
      ];
      expect(cards.length, 10);
      final capped = NarrativeRelationshipSelector.select(
        cards: cards,
        spread: spread,
        questionKind: QuestionKind.open,
        maxRelationships: 100,
      );
      expect(capped.length, lessThanOrEqualTo(12));
      final five = NarrativeRelationshipSelector.select(
        cards: cards,
        spread: spread,
        questionKind: QuestionKind.open,
        maxRelationships: 5,
      );
      expect(five.length, lessThanOrEqualTo(5));
      final zero = NarrativeRelationshipSelector.select(
        cards: cards,
        spread: spread,
        questionKind: QuestionKind.open,
        maxRelationships: 0,
      );
      expect(zero, isEmpty);

      final eleven = <NarrativeRelationshipCardContext>[
        ...cards,
        _ctxFromDeck('major_21', false, 'extra', 99),
      ];
      expect(
        () => NarrativeRelationshipSelector.select(
          cards: eleven,
          spread: spread,
          questionKind: QuestionKind.open,
          maxRelationships: 12,
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
  });

  group('3D.1E live-path / firewall', () {
    test('evidence/*.dart has no forbidden executable refs', () {
      final dir = Directory('lib/features/tarot/narrative/evidence');
      final forbidden = [
        RegExp(r'HistoryService'),
        RegExp(r'JourneyPersonalizationHints'),
        RegExp(r'SharedPreferences'),
        RegExp(r'package:http/'),
        RegExp(r'package:dio/'),
        RegExp(r'firebase', caseSensitive: false),
        RegExp(r'InterpretationEngine'),
        RegExp(r'TarotInterpretationService'),
        RegExp(r'AiInterpretationExecutor'),
      ];
      for (final file in dir.listSync().whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final src = file.readAsStringSync();
        for (final p in forbidden) {
          expect(p.hasMatch(src), isFalse, reason: '${file.path} ${p.pattern}');
        }
      }
    });

    test('builder memory/recurrence empty; theme does not leak historical', () {
      final corpus = loadEvidenceCorpus();
      final scenarios = (corpus['scenarios'] as List)
          .cast<Map<String, dynamic>>();
      var themeSeen = 0;
      for (final s in scenarios) {
        final req = NarrativeEvidenceBuilder.build(inputFromScenario(s));
        expect(req.memory.included, isFalse);
        expect(req.memory.omitReason, 'empty');
        expect(req.recurringCards, isEmpty);
        expect(req.recurringThemes, isEmpty);
        expect(req.memory.recentCardNames, isEmpty);
        expect(req.memory.recurringThemeLabels, isEmpty);
        if (req.relationships.any((r) => r.kind.name == 'themeRepetition')) {
          themeSeen++;
        }
      }
      expect(themeSeen, greaterThan(0));
    });

    test('no NarrativeEvidenceBuilder importers outside evidence/', () {
      final lib = Directory('lib');
      final hits = <String>[];
      for (final f in lib.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        if (f.path.contains('narrative${Platform.pathSeparator}evidence')) {
          continue;
        }
        final src = f.readAsStringSync();
        if (src.contains('NarrativeEvidenceBuilder') ||
            src.contains('NarrativeRelationshipScorer') ||
            src.contains('NarrativeRelationshipSelector')) {
          hits.add(f.path);
        }
      }
      expect(hits, isEmpty, reason: hits.join('\n'));
    });
  });

  group('3D.1E error privacy', () {
    test('exception messages omit question / intention text', () {
      try {
        NarrativeEvidenceBuilder.build(
          NarrativeEvidenceInput(
            sessionId: 's',
            readingId: 'r',
            languageCode: 'en',
            questionRaw: 'SECRET_QUESTION_TEXT_XYZ',
            intentionTopic: 'SECRET_INTENTION_ABC',
            spreadType: TarotSpreadType.single,
            cards: const [
              NarrativeEvidenceCardInput(
                canonicalCardId: 'not_a_card',
                ritualCardId: 0,
                isReversed: false,
                positionKey: 'sign',
                positionIndex: 0,
              ),
            ],
          ),
        );
        fail('expected throw');
      } on NarrativeEvidenceException catch (e) {
        expect(e.toString(), isNot(contains('SECRET_QUESTION')));
        expect(e.toString(), isNot(contains('SECRET_INTENTION')));
      }
    });
  });
}

NarrativeRelationshipCardContext _ctxFromDeck(
  String id,
  bool reversed,
  String positionKey,
  int positionIndex,
) {
  final deck = OraclyTarotDeck.byId(id)!;
  final profile = NarrativeTarotProfileCatalog.lookup(id)!;
  final slice = TarotNarrativeProfileSlice.fromProfile(
    profile,
    isReversed: reversed,
    questionKind: QuestionKind.open,
  );
  return NarrativeRelationshipCardContext(
    canonicalCardId: id,
    positionKey: positionKey,
    positionIndex: positionIndex,
    isReversed: reversed,
    suit: deck.suit,
    number: deck.number,
    keywordIds: slice.keywordIds,
    semanticChannel: NarrativeSemanticChannel.from(
      keywordIds: slice.keywordIds,
      symbolTags: slice.symbolTags,
    ),
    transforms: slice.transforms,
    relatedIds: deck.relationshipWithOtherCards.relatedIds,
  );
}
