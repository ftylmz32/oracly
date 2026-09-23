/// Phase 3D.1D — frozen real-deck corpus vs NarrativeEvidenceBuilder.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';

import 'narrative_evidence_test_support.dart';

void main() {
  final corpus = loadEvidenceCorpus();
  final scenarios = (corpus['scenarios'] as List).cast<Map<String, dynamic>>();

  test('corpus size and real-deck integrity', () {
    expect(scenarios.length, greaterThanOrEqualTo(40));
    for (final s in scenarios) {
      final input = inputFromScenario(s);
      for (final c in input.cards) {
        expect(OraclyTarotDeck.byId(c.canonicalCardId), isNotNull);
        expect(
          NarrativeTarotProfileCatalog.lookup(c.canonicalCardId),
          isNotNull,
        );
        final bridged = OraclyTarotBridge.byRitualId(c.ritualCardId);
        expect(bridged, isNotNull);
        expect(bridged!.id, c.canonicalCardId);
      }
    }
  });

  test('spread / question / reversed distribution', () {
    final spreads = <String, int>{};
    final kinds = <String, int>{};
    var reversedScenarios = 0;
    for (final s in scenarios) {
      final input = s['input'] as Map<String, dynamic>;
      final expected = s['expected'] as Map<String, dynamic>;
      spreads[input['spreadType'] as String] =
          (spreads[input['spreadType'] as String] ?? 0) + 1;
      final qk = (expected['question'] as Map)['kind'] as String;
      kinds[qk] = (kinds[qk] ?? 0) + 1;
      if ((input['cards'] as List).any(
        (c) => (c as Map)['isReversed'] == true,
      )) {
        reversedScenarios++;
      }
    }
    expect(spreads['single'] ?? 0, greaterThanOrEqualTo(4));
    expect(spreads['threeCard'] ?? 0, greaterThanOrEqualTo(8));
    expect(spreads['fiveCard'] ?? 0, greaterThanOrEqualTo(8));
    expect(spreads['sevenCard'] ?? 0, greaterThanOrEqualTo(8));
    expect(spreads['celticCross'] ?? 0, greaterThanOrEqualTo(12));
    expect(kinds['open'] ?? 0, greaterThanOrEqualTo(8));
    expect(kinds['guidance'] ?? 0, greaterThanOrEqualTo(8));
    expect(kinds['relationship'] ?? 0, greaterThanOrEqualTo(8));
    expect(kinds['decision'] ?? 0, greaterThanOrEqualTo(8));
    expect(reversedScenarios, greaterThanOrEqualTo(20));
  });

  test('every scenario matches frozen expected output', () {
    for (final s in scenarios) {
      final expected = s['expected'] as Map<String, dynamic>;
      final req = NarrativeEvidenceBuilder.build(inputFromScenario(s));
      expect(req.languageCode, expected['languageCode']);
      expect(
        req.narrativeTarotVersion,
        TarotNarrativeRequest.currentNarrativeVersion,
      );
      expect(req.question.kind.name, (expected['question'] as Map)['kind']);
      expect(
        req.question.hasRealQuestion,
        (expected['question'] as Map)['hasRealQuestion'],
      );
      expect(
        req.cards.map((c) => c.canonicalCardId).toList(),
        expected['cardOrder'],
      );
      expect(req.relationships.length, expected['relationshipCount']);
      final expRels = (expected['relationships'] as List).cast<Map>();
      expect(req.relationships, hasLength(expRels.length));
      for (var i = 0; i < expRels.length; i++) {
        final er = expRels[i];
        final ar = req.relationships[i];
        expect(ar.evidenceId, er['evidenceId']);
        expect(ar.leftCardId, er['leftCardId']);
        expect(ar.rightCardId, er['rightCardId']);
        expect(ar.leftPositionKey, er['leftPositionKey']);
        expect(ar.rightPositionKey, er['rightPositionKey']);
        expect(ar.kind.name, er['kind']);
        expect(ar.provenance, er['provenance']);
        expect(ar.strength, closeTo((er['strength'] as num).toDouble(), 1e-6));
        expect(ar.noteKeyOrText, isNull);
      }
      expect(req.memory.included, isFalse);
      expect(req.memory.omitReason, 'empty');
      expect(req.recurringCards, isEmpty);
      expect(req.recurringThemes, isEmpty);
      expect(req.bounds.maxRelationships, 12);
      expect(req.bounds.maxPriorReadingsScanned, 20);
      expect(req.bounds.maxRecurringOccurrencesListed, 5);
      expect(req.bounds.maxMemoryChars, 800);
      expect(req.bounds.maxThemeLabels, 4);
    }
  });

  test('relationship kind coverage 10/10', () {
    final found = <String>{};
    for (final s in scenarios) {
      final expected = s['expected'] as Map<String, dynamic>;
      for (final k in (expected['relationshipKinds'] as List?) ?? const []) {
        found.add(k as String);
      }
      for (final r in (expected['relationships'] as List).cast<Map>()) {
        found.add(r['kind'] as String);
      }
    }
    for (final k in RelationshipKind.values) {
      expect(found, contains(k.name), reason: 'missing kind ${k.name}');
    }
    expect(found.length, RelationshipKind.values.length);
  });

  test('no-relation / sparse scenarios exist', () {
    final sparse = scenarios.where((s) {
      final n = (s['expected'] as Map)['relationshipCount'] as int;
      return n == 0;
    }).length;
    expect(sparse, greaterThanOrEqualTo(5));
  });

  test('FR sentinels do not emit false strong page/court support', () {
    for (final s in scenarios) {
      final tags = (s['tags'] as List?)?.cast<String>() ?? const [];
      if (!tags.any((t) => t.contains('fr_'))) continue;
      final req = NarrativeEvidenceBuilder.build(inputFromScenario(s));
      for (final rel in req.relationships) {
        final pair = {rel.leftCardId, rel.rightCardId};
        final isF01 =
            pair.contains('wands_11') && pair.contains('pentacles_11');
        final isF02 = pair.contains('swords_11') && pair.contains('swords_12');
        if (isF01 || isF02) {
          expect(rel.strength, lessThanOrEqualTo(0.45));
          expect(rel.kind, isNot(RelationshipKind.support));
          expect(rel.kind, isNot(RelationshipKind.reinforcement));
        }
      }
    }
  });

  test('fixture must not contain forbidden safety prose tokens', () {
    final raw = loadEvidenceCorpus().toString();
    for (final bad in [
      'partnerIsJealous',
      'cheating',
      'criminality',
      'mentalIllness',
      'pregnancy',
      'guaranteedOutcome',
      'destinedPartner',
      'mindReadingClaim',
    ]) {
      expect(raw.contains(bad), isFalse, reason: bad);
    }
  });
}
