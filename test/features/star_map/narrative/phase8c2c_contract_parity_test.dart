/// Phase 8C.2c — the Flutter representation of the frozen Yıldızname
/// Narrative V1 wire contract agrees with the deployed candidate 169c514a
/// backend for every ceiling that actually governs wire acceptance.
///
/// No real provider call is used for any boundary test here.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_response_parser.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_house_system.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_policy.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_extras.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_factory.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_wire_contract.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_error.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';
import 'package:oracly_new/features/star_map/narrative/versions.dart';

import 'fixtures/narrative_evidence_fixtures.dart';
import 'phase8a_live_plan_support.dart';

// ---------------------------------------------------------------------------
// Backend ceilings (candidate 169c514a, backend/src/ai/narrative-yildizname-
// limits.ts). Pinned here as plain numbers so a future backend edit that
// silently drifts the frozen contract shows up as a client-side test diff,
// not just a production incident.
// ---------------------------------------------------------------------------
const _backendMaxThemes = 3;
const _backendMaxPlacements = 10;
const _backendMaxHouses = 12;
const _backendMaxAspects = 48;
const _backendMaxAngles = 2;
const _backendMaxOmittedLayers = 20;
const _backendMaxLabelChars = 120;
const _backendMaxOmittedLayerChars = 40;
const _backendMaxCalculationVersionChars = 64;
const _backendMaxOrb = 12;
const _backendMaxBodyChars = 24;
const _backendMaxSignChars = 24;
const _backendMaxFactRefChars = 80;
const _backendMaxThemeRefChars = 64;
const _backendMaxFactRefsPerBlock = 12;
const _backendMaxThemeRefsPerBlock = 3;
const _backendSummary = 1200;
const _backendSection = 1600;
const _backendReflectionPrompt = 400;
const _backendClosingMessage = 600;
const _backendHouseSystems = {'wholeSign'};
const _backendCertainties = {'exact', 'intervalStable'};
const _backendOmittedLayers = {
  'moon',
  'exactDegrees',
  'ascendant',
  'midheaven',
  'houses',
  'aspects',
  'retrograde',
  'balances',
  'angles',
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
  'uranus',
  'neptune',
  'pluto',
  'transits',
};
const _backendBodies = {
  'sun',
  'moon',
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
  'uranus',
  'neptune',
  'pluto',
};
const _backendPolicyRules = [
  'USE_ONLY_SUPPLIED_FACTS',
  'DO_NOT_CALCULATE_ASTRONOMY',
  'DO_NOT_INVENT_MEMORY',
  'DO_NOT_INVENT_PLACEMENTS',
  'DO_NOT_INVENT_HOUSES',
  'DO_NOT_INVENT_ASPECTS',
  'DO_NOT_TREAT_SYMBOLIC_INTERPRETATION_AS_CERTAINTY',
  'NO_DETERMINISTIC_FUTURE',
  'NO_FATALISM',
  'NO_MEDICAL_DIAGNOSIS',
  'NO_PREGNANCY_CERTAINTY',
  'NO_LEGAL_FINANCIAL_GUARANTEE',
  'NO_GUARANTEED_SOULMATE',
  'KARMIC_LANGUAGE_METAPHOR_ONLY',
];

/// The 10 frozen section kinds, in order — the real ceiling on section
/// count, since the parser rejects a duplicate kind before any count check
/// is ever reached.
const _sectionKinds = [
  'core_identity',
  'emotional_world',
  'mind_and_expression',
  'relationships_and_values',
  'drive_and_growth',
  'angles_and_houses',
  'patterns_and_tensions',
  'strengths_and_resources',
  'archive_echo',
  'practical_reflection',
];

/// A backend-shaped (frozen) result map. Overrides replace whole fields.
Map<String, dynamic> _backendResult({
  String summary = 'A steady sense of focus runs through this reading.',
  List<String> summaryFactRefs = const ['placement.sun'],
  String sectionText = 'Identity here reads as patient and warm.',
  List<String> sectionFactRefs = const ['placement.sun'],
  List<String> sectionThemeRefs = const [],
  Object? reflectionPrompt = 'Which habit feeds you slowly but surely?',
  Object? closingMessage = 'Come back to your own rhythm whenever you like.',
  int sectionCount = 1,
}) => {
  'contractVersion': kYildiznameResultContractVersion,
  'languageCode': 'en',
  'scope': 'reduced',
  'summary': {
    'text': summary,
    'factRefs': summaryFactRefs,
    'themeRefs': const <String>[],
  },
  'sections': [
    for (var i = 0; i < sectionCount; i++)
      {
        // Each section needs a DISTINCT kind — the parser rejects a
        // duplicate — so only the first `_sectionKinds.length` (10) values
        // of [sectionCount] can ever produce a valid response.
        'kind': _sectionKinds[i % _sectionKinds.length],
        'text': sectionText,
        'factRefs': sectionFactRefs,
        'themeRefs': sectionThemeRefs,
      },
  ],
  'reflectionPrompt': reflectionPrompt,
  'closingMessage': closingMessage,
};

dynamic _parse(Map<String, dynamic> data) => YildiznameResultParser.parse(data);

Matcher _rejectsBounds(String key) => throwsA(
  isA<YildiznameResultException>()
      .having((e) => e.kind, 'kind', YildiznameResultErrorKind.bounds)
      .having((e) => e.message, 'message', key),
);

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  group('client ceilings equal the backend ceilings they mirror', () {
    test('request-side WIRE ceilings', () {
      expect(kYildiznameMaxThemes, _backendMaxThemes);
    });

    test('result-side WIRE ceilings', () {
      expect(kYildiznameMaxSummaryChars, _backendSummary);
      expect(kYildiznameMaxSectionChars, _backendSection);
      expect(kYildiznameMaxReflectionChars, _backendReflectionPrompt);
      expect(kYildiznameMaxClosingChars, _backendClosingMessage);
      expect(kYildiznameMaxFactRefsPerBlock, _backendMaxFactRefsPerBlock);
      expect(kYildiznameMaxThemeRefsPerBlock, _backendMaxThemeRefsPerBlock);
      expect(kYildiznameMaxFactRefChars, _backendMaxFactRefChars);
      expect(kYildiznameMaxThemeRefChars, _backendMaxThemeRefChars);
    });

    test('the frozen policy rules are identical, in order', () {
      expect(YildiznameNarrativePolicy.rules, _backendPolicyRules);
    });

    test(
      'the only house system produced is the only one the backend allows',
      () {
        expect(
          NatalHouseSystem.values.map((v) => v.name).toSet(),
          _backendHouseSystems,
        );
      },
    );

    test('the aspect engine never exceeds the backend orb ceiling', () {
      for (final t in AspectType.values) {
        expect(t.defaultOrb, lessThanOrEqualTo(_backendMaxOrb), reason: t.name);
      }
    });
  });

  group('result parser — boundary values', () {
    test('summary: exactly the ceiling PASSes, ceiling+1 is rejected', () {
      final ok = _backendResult(summary: 'a' * kYildiznameMaxSummaryChars);
      expect(() => _parse(ok), returnsNormally);
      final over = _backendResult(
        summary: 'a' * (kYildiznameMaxSummaryChars + 1),
      );
      expect(() => _parse(over), _rejectsBounds('text'));
    });

    test('section: exactly the ceiling PASSes, ceiling+1 is rejected', () {
      final ok = _backendResult(sectionText: 'a' * kYildiznameMaxSectionChars);
      expect(() => _parse(ok), returnsNormally);
      final over = _backendResult(
        sectionText: 'a' * (kYildiznameMaxSectionChars + 1),
      );
      expect(() => _parse(over), _rejectsBounds('text'));
    });

    test(
      'reflectionPrompt: exactly the ceiling PASSes, ceiling+1 is rejected',
      () {
        final ok = _backendResult(
          reflectionPrompt: 'a' * kYildiznameMaxReflectionChars,
        );
        expect(() => _parse(ok), returnsNormally);
        final over = _backendResult(
          reflectionPrompt: 'a' * (kYildiznameMaxReflectionChars + 1),
        );
        expect(() => _parse(over), _rejectsBounds('reflectionPrompt'));
      },
    );

    test(
      'closingMessage: exactly the ceiling PASSes, ceiling+1 is rejected',
      () {
        final ok = _backendResult(
          closingMessage: 'a' * kYildiznameMaxClosingChars,
        );
        expect(() => _parse(ok), returnsNormally);
        final over = _backendResult(
          closingMessage: 'a' * (kYildiznameMaxClosingChars + 1),
        );
        expect(() => _parse(over), _rejectsBounds('closingMessage'));
      },
    );

    test('factRefs: exactly 12 refs, each exactly 80 chars, PASS', () {
      final ok = _backendResult(
        summaryFactRefs: [
          for (var i = 0; i < 12; i++)
            ('a' * (kYildiznameMaxFactRefChars - 2)) +
                i.toString().padLeft(2, '0'),
        ],
      );
      expect(() => _parse(ok), returnsNormally);
    });

    test('factRefs: 13 refs is rejected (count ceiling)', () {
      final over = _backendResult(
        summaryFactRefs: [for (var i = 0; i < 13; i++) 'placement.sun.$i'],
      );
      expect(() => _parse(over), _rejectsBounds('factRefs'));
    });

    test('a single factRef of exactly 80 chars PASSes, 81 is rejected', () {
      final ok = _backendResult(
        summaryFactRefs: ['a' * kYildiznameMaxFactRefChars],
      );
      expect(() => _parse(ok), returnsNormally);
      final over = _backendResult(
        summaryFactRefs: ['a' * (kYildiznameMaxFactRefChars + 1)],
      );
      expect(() => _parse(over), throwsA(isA<YildiznameResultException>()));
    });

    test('themeRefs: exactly 3 refs PASS, 4 is rejected (count ceiling)', () {
      final ok = _backendResult(
        sectionThemeRefs: const ['theme.0', 'theme.1', 'theme.2'],
      );
      expect(() => _parse(ok), returnsNormally);
      final over = _backendResult(
        sectionThemeRefs: const ['theme.0', 'theme.1', 'theme.2', 'theme.3'],
      );
      expect(() => _parse(over), _rejectsBounds('themeRefs'));
    });

    test('a single themeRef of exactly 64 chars PASSes, 65 is rejected', () {
      final ok = _backendResult(
        sectionThemeRefs: ['a' * kYildiznameMaxThemeRefChars],
      );
      expect(() => _parse(ok), returnsNormally);
      final over = _backendResult(
        sectionThemeRefs: ['a' * (kYildiznameMaxThemeRefChars + 1)],
      );
      expect(() => _parse(over), throwsA(isA<YildiznameResultException>()));
    });

    test('sections: all 10 distinct kinds PASS — the real ceiling is the '
        'kind enum (10), so the client\'s raw count ceiling (12) is dead '
        'slack that can never actually be reached, and never rejects a '
        'genuine backend response', () {
      expect(() => _parse(_backendResult(sectionCount: 10)), returnsNormally);
      // An 11th section can only repeat an already-used kind (only 10
      // exist), so it is rejected as a DUPLICATE, never by the raw count
      // ceiling — proving 10 (backend's real maximum) is enforced either way.
      expect(
        () => _parse(_backendResult(sectionCount: 11)),
        throwsA(
          isA<YildiznameResultException>().having(
            (e) => e.kind,
            'kind',
            YildiznameResultErrorKind.duplicate,
          ),
        ),
      );
    });
  });

  group(
    'request side — real production evidence never exceeds backend ceilings',
    () {
      test('FULL (canonical E4 evidence): placements/houses/angles/aspects', () {
        final chart = phase8aChart(phase8aE4Profile());
        final evidence = chart.natalEvidence!;
        final req = YildiznameRequestFactory.fromEvidence(
          evidence: evidence,
          languageCode: 'tr',
        );
        expect(req.placements.length, lessThanOrEqualTo(_backendMaxPlacements));
        expect(req.houses.length, lessThanOrEqualTo(_backendMaxHouses));
        expect(req.angles.length, lessThanOrEqualTo(_backendMaxAngles));
        expect(req.aspects.length, lessThanOrEqualTo(_backendMaxAspects));
        expect(
          req.discoveryThemes.length,
          lessThanOrEqualTo(_backendMaxThemes),
        );
        expect(req.balances.length, 2);
        // Structural ceilings this evidence actually reaches.
        expect(req.placements.length, 10);
        expect(req.houses.length, 12);
        expect(req.angles.length, 2);

        final json = req.toProviderJson();
        for (final p in json['placements'] as List) {
          final m = p as Map;
          expect(
            (m['body'] as String).length,
            lessThanOrEqualTo(_backendMaxBodyChars),
          );
          expect(
            (m['sign'] as String).length,
            lessThanOrEqualTo(_backendMaxSignChars),
          );
          expect(
            _backendCertainties.contains(m['certainty']),
            isTrue,
            reason: '$m',
          );
          expect(
            (m['factRef'] as String).length,
            lessThanOrEqualTo(_backendMaxFactRefChars),
          );
        }
        for (final a in json['aspects'] as List) {
          final m = a as Map;
          expect((m['orb'] as num), lessThanOrEqualTo(_backendMaxOrb));
          expect(_backendCertainties.contains(m['certainty']), isTrue);
        }
        expect(json['houseSystem'], 'wholeSign');
        final calcVersion = json['calculationVersion'] as String?;
        if (calcVersion != null) {
          expect(
            calcVersion.length,
            lessThanOrEqualTo(_backendMaxCalculationVersionChars),
          );
        }
        // REDUCED/FULL omittedLayers must be values the frozen backend enum
        // actually knows (legacy's own list is verified separately below —
        // it never reaches the wire at all).
        for (final layer in req.omittedLayers) {
          expect(
            _backendOmittedLayers.contains(layer) ||
                _backendBodies.contains(layer),
            isTrue,
            reason:
                'omitted layer "$layer" is not a value the frozen backend accepts',
          );
          expect(layer.length, lessThanOrEqualTo(_backendMaxOmittedLayerChars));
        }
        expect(
          req.omittedLayers.length,
          lessThanOrEqualTo(_backendMaxOmittedLayers),
        );
      });

      test('REDUCED (canonical E2 evidence): omittedLayers stay within the '
          'backend enum', () {
        final chart = phase8aChart(phase8aE2Profile());
        final req = YildiznameRequestFactory.fromEvidence(
          evidence: chart.natalEvidence!,
          languageCode: 'tr',
        );
        for (final layer in req.omittedLayers) {
          expect(
            _backendOmittedLayers.contains(layer) ||
                _backendBodies.contains(layer),
            isTrue,
            reason: layer,
          );
        }
      });

      test('REDUCED WITH AN AMBIGUOUS MOON (regression): the wire request no '
          'longer contains the invalid synthetic "ambiguous.moon" marker — the '
          'frozen backend enum has no such value and would have rejected the '
          'whole request', () {
        final req = YildiznameRequestFactory.fromEvidence(
          evidence: NarrativeEvidenceFixtures.reducedAmbiguousMoon(),
          languageCode: 'tr',
        );
        expect(req.placements.any((p) => p.body == 'moon'), isFalse);
        for (final layer in req.omittedLayers) {
          expect(
            _backendOmittedLayers.contains(layer) ||
                _backendBodies.contains(layer),
            isTrue,
            reason:
                'omitted layer "$layer" is not a value the frozen backend accepts',
          );
        }
        expect(req.omittedLayers.any((l) => l.contains('ambiguous')), isFalse);
      });

      test('LEGACY evidence never reaches the wire (its internal-only marker '
          'is never validated by the backend)', () {
        final chart = phase8aChart(phase8aE1Profile());
        final plan = YildiznameLivePlanBuilder.build(
          featureEnabled: true,
          ownerId: 'owner-x',
          chart: chart,
          languageCode: 'tr',
        );
        expect(plan.kind, YildiznameLivePlanKind.legacyLocal);
        // legacyLocal carries no request at all — nothing is ever serialized
        // or sent for this scope, so its `personalPlanets` marker (used only
        // by the local, frozen Phase 7B scope resolver) is provably unreachable
        // from `YildiznameWireContract.payload`.
        expect(plan.request, isNull);
      });

      test('theme labels: exactly 64 chars kept, 65 dropped (client is '
          'intentionally stricter than backend\'s 120)', () {
        final labels = YildiznameRequestExtras.themes([
          'a' * kYildiznameMaxThemeLabelChars,
          'b' * (kYildiznameMaxThemeLabelChars + 1),
        ]);
        expect(labels, hasLength(1));
        expect(labels.single.label.length, kYildiznameMaxThemeLabelChars);
        for (final t in labels) {
          expect(t.label.length, lessThanOrEqualTo(_backendMaxLabelChars));
        }
      });

      test(
        'themes: exactly 3 kept even when more are offered (matches backend)',
        () {
          final labels = YildiznameRequestExtras.themes([
            'a',
            'b',
            'c',
            'd',
            'e',
          ]);
          expect(labels, hasLength(_backendMaxThemes));
        },
      );
    },
  );

  group(
    'actual production FULL payload passes the frozen backend validator',
    () {
      test('offline contract proof (no network)', () async {
        final chart = phase8aChart(phase8aE4Profile());
        final req = YildiznameRequestFactory.fromEvidence(
          evidence: chart.natalEvidence!,
          languageCode: 'tr',
        );
        final payload = YildiznameWireContract.payload(req);
        // Round-trips through the exact envelope the transport sends.
        final body = {'operation': 'yildizname_reading', 'payload': payload};
        final encoded = jsonEncode(body);
        expect(encoded, isNotEmpty);
        // The offline node-based proof against the frozen 169c514a validator
        // is documented and was re-run manually for this phase (see
        // docs/product/yildizname/YILDIZNAME_PHASE8C2C_CONTRACT_PARITY.md);
        // it requires a Node/tsx toolchain this Dart test suite does not
        // carry, so it is not re-executed as part of `flutter test`.
        final narrative = payload['narrative'] as Map<String, dynamic>;
        expect(narrative['placements'], hasLength(10));
        expect(
          (narrative['aspects'] as List).every(
            (a) => (a as Map)['certainty'] == 'exact',
          ),
          isTrue,
        );
      });
    },
  );

  group(
    'the AiProxyResponseParser envelope is unaffected by these changes',
    () {
      test('a success envelope still unwraps to the data map', () {
        final raw = jsonEncode({'success': true, 'data': _backendResult()});
        final outcome = AiProxyResponseParser.parse(raw);
        expect(outcome.isFailure, isFalse);
        expect(() => _parse(outcome.value!), returnsNormally);
      });
    },
  );
}
