/// Phase 3D.1E — corpus density + contract-aligned semantic classification.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';

import '../narrative_evidence_test_support.dart';

const _allowedProvenance = {
  'keywordOverlap',
  'keywordContrast',
  'symbolTag',
  'transform',
  'canonicalRelation',
  'positionEdge',
  'orientationPair',
  'questionRelevance',
  'themeEcho',
  'pageSuitGuard',
  'courtRankGuard',
};

void main() {
  final corpus = loadEvidenceCorpus();
  final scenarios = (corpus['scenarios'] as List).cast<Map<String, dynamic>>();

  test('independent corpus metric recomputation', () {
    expect(scenarios.length, 46);
    final spreads = <String, int>{};
    final kinds = <String, int>{};
    final emissions = <String, int>{};
    var reversed = 0;
    var noRel = 0;
    for (final s in scenarios) {
      final input = s['input'] as Map<String, dynamic>;
      final expected = s['expected'] as Map<String, dynamic>;
      spreads[input['spreadType'] as String] =
          (spreads[input['spreadType'] as String] ?? 0) + 1;
      kinds[(expected['question'] as Map)['kind'] as String] =
          (kinds[(expected['question'] as Map)['kind'] as String] ?? 0) + 1;
      if ((input['cards'] as List).any(
        (c) => (c as Map)['isReversed'] == true,
      )) {
        reversed++;
      }
      final n = expected['relationshipCount'] as int;
      if (n == 0) noRel++;
      for (final r in (expected['relationships'] as List).cast<Map>()) {
        final k = r['kind'] as String;
        emissions[k] = (emissions[k] ?? 0) + 1;
      }
    }
    expect(spreads, {
      'single': 5,
      'threeCard': 9,
      'fiveCard': 10,
      'sevenCard': 9,
      'celticCross': 13,
    });
    expect(kinds, {
      'open': 11,
      'guidance': 11,
      'relationship': 12,
      'decision': 12,
    });
    expect(reversed, 38);
    expect(noRel, 9);
    expect(emissions, {
      'support': 38,
      'reinforcement': 3,
      'contrast': 27,
      'conflict': 9,
      'causeEffect': 17,
      'blockage': 7,
      'resolution': 2,
      'escalation': 6,
      'softening': 5,
      'themeRepetition': 15,
    });
  });

  test('every corpus scenario is real-deck + closed-universe rebuild', () {
    var rows = 0;
    final provenanceTokens = <String, int>{};
    final bySpreadCounts = <String, List<int>>{};
    var hit12 = 0;
    for (final s in scenarios) {
      final input = inputFromScenario(s);
      for (final c in input.cards) {
        expect(OraclyTarotDeck.byId(c.canonicalCardId), isNotNull);
        expect(
          NarrativeTarotProfileCatalog.lookup(c.canonicalCardId),
          isNotNull,
        );
        expect(
          OraclyTarotBridge.byRitualId(c.ritualCardId)!.id,
          c.canonicalCardId,
        );
      }
      final req = NarrativeEvidenceBuilder.build(input);
      final expected = s['expected'] as Map<String, dynamic>;
      expect(req.relationships.length, expected['relationshipCount']);
      final cardIds = req.cards.map((c) => c.canonicalCardId).toSet();
      final posKeys = req.spread.positions.map((p) => p.positionKey).toSet();
      final ids = <String>{};
      for (final r in req.relationships) {
        rows++;
        expect(cardIds.contains(r.leftCardId), isTrue);
        expect(cardIds.contains(r.rightCardId), isTrue);
        expect(posKeys.contains(r.leftPositionKey), isTrue);
        expect(posKeys.contains(r.rightPositionKey), isTrue);
        expect(RegExp(r'^rel_[0-9]{2}$').hasMatch(r.evidenceId), isTrue);
        expect(ids.add(r.evidenceId), isTrue);
        expect(r.strength, inInclusiveRange(0.0, 1.0));
        expect(r.noteKeyOrText, isNull);
        final tokens = r.provenance.split('|');
        expect(tokens.toSet().length, tokens.length);
        final sorted = [...tokens]..sort();
        expect(tokens, sorted);
        for (final t in tokens) {
          expect(_allowedProvenance.contains(t), isTrue, reason: t);
          provenanceTokens[t] = (provenanceTokens[t] ?? 0) + 1;
        }
      }
      expect(req.relationships.length, lessThanOrEqualTo(12));
      if (req.relationships.length == 12) hit12++;
      final st = (s['input'] as Map)['spreadType'] as String;
      bySpreadCounts.putIfAbsent(st, () => []).add(req.relationships.length);
    }

    expect(rows, 129);
    expect(hit12, lessThanOrEqualTo(2));
    // ignore: avoid_print
    print({
      'provenance': provenanceTokens,
      'hit12': hit12,
      'bySpread': {
        for (final e in bySpreadCounts.entries)
          e.key: {
            'min': e.value.reduce((a, b) => a < b ? a : b),
            'max': e.value.reduce((a, b) => a > b ? a : b),
            'median': (() {
              final v = [...e.value]..sort();
              return v[v.length ~/ 2];
            })(),
          },
      },
    });
  });

  test('contract rebuild classifies all 129 rows as JUSTIFIED', () {
    var justified = 0;
    for (final s in scenarios) {
      final expected = s['expected'] as Map<String, dynamic>;
      final req = NarrativeEvidenceBuilder.build(inputFromScenario(s));
      final exp = (expected['relationships'] as List).cast<Map>();
      expect(req.relationships.length, exp.length);
      for (var i = 0; i < exp.length; i++) {
        final er = exp[i];
        final ar = req.relationships[i];
        expect(ar.kind.name, er['kind']);
        expect(ar.provenance, er['provenance']);
        expect(ar.strength, closeTo((er['strength'] as num).toDouble(), 1e-6));
        justified++;
      }
    }
    expect(justified, 129);
    expect(RelationshipKind.values.length, 10);
  });

  test('no fixture writer / runtime expected=actual in evidence tests', () {
    final dir = Directory('test/features/tarot/narrative_evidence');
    var writeHits = 0;
    var expectedEqualsActual = 0;
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      if (f.path
          .replaceAll('\\', '/')
          .endsWith('narrative_evidence_corpus_semantic_audit_test.dart')) {
        continue;
      }
      final src = f.readAsStringSync();
      if (src.contains('writeAsStringSync') || src.contains('writeAsString(')) {
        writeHits++;
      }
      if (src.contains('expected = actual') ||
          src.contains('expected=actual')) {
        expectedEqualsActual++;
      }
    }
    expect(writeHits, 0);
    expect(expectedEqualsActual, 0);
  });
}
