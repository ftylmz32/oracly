/// Phase 8C.2a — the FULL Narrative wire carries aspect `certainty`.
///
/// The frozen backend contract (`parseAspect`) requires `certainty` on every
/// FULL aspect and only accepts `exact`. The client used to omit it, so every
/// FULL request with an aspect was rejected (`invalid_request`) before the
/// provider. These tests drive the REAL production path —
/// `YildiznameRequestFactory.fromEvidence` → `YildiznameNarrativeRequest` →
/// `toProviderJson()` — never a hand-built aspect fact.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/astronomical_fact_certainty.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_aspect.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_chart_evidence.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_request.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_factory.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_fingerprint.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_wire_contract.dart';

import 'fixtures/narrative_evidence_fixtures.dart';
import 'phase8a_live_plan_support.dart';

YildiznameNarrativeRequest _request(NatalChartEvidence evidence) =>
    YildiznameRequestFactory.fromEvidence(
      evidence: evidence,
      languageCode: 'tr',
    );

List<Map<String, dynamic>> _aspects(YildiznameNarrativeRequest r) => [
  for (final a in r.toProviderJson()['aspects'] as List)
    a as Map<String, dynamic>,
];

/// Same evidence, every aspect stamped with [certainty] (typed, no JSON).
NatalChartEvidence _withAspectCertainty(
  NatalChartEvidence ev,
  AstronomicalFactCertainty certainty,
) => NatalChartEvidence(
  fidelity: ev.fidelity,
  metadata: ev.metadata,
  placements: ev.placements,
  houses: ev.houses,
  aspects: [
    for (final a in ev.aspects)
      NatalAspect(
        bodyA: a.bodyA,
        bodyB: a.bodyB,
        type: a.type,
        orb: a.orb,
        certainty: certainty,
        provenance: a.provenance,
      ),
  ],
  elementBalance: ev.elementBalance,
  modalityBalance: ev.modalityBalance,
  ascendant: ev.ascendant,
  midheaven: ev.midheaven,
  houseSystem: ev.houseSystem,
);

const _aspectWireKeys = {
  'factRef',
  'bodyA',
  'bodyB',
  'type',
  'orb',
  'certainty',
};

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  group('FULL — every aspect is serialized with certainty from evidence', () {
    final evidences = <String, NatalChartEvidence Function()>{
      'real E4 engine evidence': () =>
          phase8aChart(phase8aE4Profile()).natalEvidence!,
      'canonical FULL fixture': NarrativeEvidenceFixtures.fullNatal,
    };

    evidences.forEach((name, build) {
      test('$name → certainty "exact" on every aspect', () {
        final evidence = build();
        expect(evidence.aspects, isNotEmpty);
        final request = _request(evidence);
        expect(request.scope, YildiznameNarrativeScope.full);

        final wire = _aspects(request);
        expect(wire, isNotEmpty, reason: 'FULL aspects remain present');
        expect(wire, hasLength(evidence.aspects.length));
        for (var i = 0; i < wire.length; i++) {
          final a = wire[i];
          expect(a.keys.toSet(), _aspectWireKeys, reason: 'aspect $i keys');
          expect(a['certainty'], 'exact', reason: 'aspect $i');
          expect(
            a['certainty'],
            evidence.aspects[i].certainty.name,
            reason: 'aspect $i comes from NatalAspect.certainty',
          );
          expect(a['bodyA'], evidence.aspects[i].bodyA.name);
          expect(a['bodyB'], evidence.aspects[i].bodyB.name);
          expect(a['type'], evidence.aspects[i].type.name);
          expect(a['orb'], evidence.aspects[i].orb);
        }
      });
    });

    test('the transport payload (wire contract wrapper) carries it too', () {
      final request = _request(phase8aChart(phase8aE4Profile()).natalEvidence!);
      final payload = YildiznameWireContract.payload(request);
      final narrative = payload['narrative'] as Map<String, dynamic>;
      final aspects = (narrative['aspects'] as List)
          .cast<Map<String, dynamic>>();
      expect(aspects, isNotEmpty);
      expect(aspects.every((a) => a['certainty'] == 'exact'), isTrue);
    });

    test('certainty is the evidence value, never a hard-coded "exact"', () {
      final real = phase8aChart(phase8aE4Profile()).natalEvidence!;
      final stamped = _withAspectCertainty(
        real,
        AstronomicalFactCertainty.intervalStable,
      );
      final wire = _aspects(_request(stamped));
      expect(wire, isNotEmpty);
      expect(wire.every((a) => a['certainty'] == 'intervalStable'), isTrue);
    });
  });

  group('scopes without aspects are unchanged', () {
    test('REDUCED (real E2 engine evidence) still has zero aspects', () {
      final evidence = phase8aChart(phase8aE2Profile()).natalEvidence!;
      final request = _request(evidence);
      expect(request.scope, YildiznameNarrativeScope.reduced);
      expect(request.aspects, isEmpty);
      expect(request.toProviderJson()['aspects'], isEmpty);
    });

    test('REDUCED fixture still has zero aspects', () {
      final request = _request(NarrativeEvidenceFixtures.reducedStable());
      expect(request.scope, YildiznameNarrativeScope.reduced);
      expect(request.toProviderJson()['aspects'], isEmpty);
    });

    test('LEGACY request is unchanged (no aspects, placement keys intact)', () {
      final request = _request(NarrativeEvidenceFixtures.legacySun());
      expect(request.scope, YildiznameNarrativeScope.legacy);
      final json = request.toProviderJson();
      expect(json['aspects'], isEmpty);
      final placement = (json['placements'] as List).single as Map;
      expect(placement.keys.toSet(), {'factRef', 'body', 'sign', 'certainty'});
    });
  });

  group('no private / raw birth field is introduced', () {
    test('FULL wire JSON stays free of forbidden keys', () {
      final request = _request(phase8aChart(phase8aE4Profile()).natalEvidence!);
      final encoded = jsonEncode(request.toProviderJson());
      for (final forbidden in const [
        'ownerId',
        'userId',
        'uid',
        'latitude',
        'longitude',
        'timezoneId',
        'birthTime',
        'birthDate',
        'birthPlace',
        'utcInstant',
        'provenance',
        'sourceId',
        'artifactId',
      ]) {
        expect(
          encoded.contains('"$forbidden"'),
          isFalse,
          reason: 'wire leaks "$forbidden"',
        );
      }
      // The only new aspect field is the contract-required certainty.
      for (final a in _aspects(request)) {
        expect(a.keys.toSet(), _aspectWireKeys);
      }
    });
  });

  group('fingerprint (natural consequence only)', () {
    test('is deterministic for the corrected FULL request', () {
      final ev = phase8aChart(phase8aE4Profile()).natalEvidence!;
      expect(
        YildiznameRequestFingerprint.of(_request(ev)),
        YildiznameRequestFingerprint.of(_request(ev)),
      );
    });

    test('now covers the previously missing contract field', () {
      final real = phase8aChart(phase8aE4Profile()).natalEvidence!;
      final other = _withAspectCertainty(
        real,
        AstronomicalFactCertainty.intervalStable,
      );
      expect(
        YildiznameRequestFingerprint.of(_request(real)),
        isNot(YildiznameRequestFingerprint.of(_request(other))),
      );
    });

    test('REDUCED / LEGACY fingerprints do not depend on aspect certainty', () {
      final reduced = NarrativeEvidenceFixtures.reducedStable();
      expect(
        YildiznameRequestFingerprint.of(_request(reduced)),
        YildiznameRequestFingerprint.of(
          _request(
            _withAspectCertainty(reduced, AstronomicalFactCertainty.exact),
          ),
        ),
      );
    });
  });
}
