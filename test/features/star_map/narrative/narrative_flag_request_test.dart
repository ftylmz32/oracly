/// Feature flag + request factory + privacy tests.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_narrative_live_gate.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_factory.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_fingerprint.dart';

import 'fixtures/narrative_evidence_fixtures.dart';

void main() {
  tearDown(() => FeatureFlagRuntime.refreshFromRemote(const {}));

  test('yildiznameNarrativeV1 defaults false and is catalogued', () {
    expect(ProductFeatureFlags.yildiznameNarrativeV1.key,
        'yildizname_narrative_v1');
    expect(ProductFeatureFlags.yildiznameNarrativeV1.defaultValue, isFalse);
    expect(ProductFeatureFlags.defaults()['yildizname_narrative_v1'], isFalse);
    expect(
      ProductFeatureFlags.definitionFor('yildizname_narrative_v1'),
      same(ProductFeatureFlags.yildiznameNarrativeV1),
    );
    expect(YildiznameNarrativeLiveGate.isEnabled, isFalse);
  });

  test('factory maps fidelities to scopes', () {
    final legacy = YildiznameRequestFactory.fromEvidence(
      evidence: NarrativeEvidenceFixtures.legacySun(),
      languageCode: 'tr',
    );
    expect(legacy.scope, YildiznameNarrativeScope.legacy);
    expect(legacy.placements, hasLength(1));
    expect(legacy.placements.first.body, 'sun');
    expect(legacy.angles, isEmpty);
    expect(legacy.houses, isEmpty);
    expect(legacy.aspects, isEmpty);

    final reduced = YildiznameRequestFactory.fromEvidence(
      evidence: NarrativeEvidenceFixtures.reducedStable(),
      languageCode: 'en',
    );
    expect(reduced.scope, YildiznameNarrativeScope.reduced);
    expect(reduced.placements.length, greaterThanOrEqualTo(2));
    expect(reduced.placements.every((p) => p.degreeWithinSign == null), isTrue);
    expect(reduced.angles, isEmpty);

    final full = YildiznameRequestFactory.fromEvidence(
      evidence: NarrativeEvidenceFixtures.fullNatal(),
      languageCode: 'ru',
    );
    expect(full.scope, YildiznameNarrativeScope.full);
    expect(full.angles, isNotEmpty);
    expect(full.houses, isNotEmpty);
    expect(full.aspects, isNotEmpty);
  });

  test('ambiguous moon is omitted; themes capped; privacy in JSON', () {
    final req = YildiznameRequestFactory.fromEvidence(
      evidence: NarrativeEvidenceFixtures.reducedAmbiguousMoon(),
      languageCode: 'tr',
      observedRecurringLabels: const [
        'sabır',
        'derinlik',
        'sınır',
        'fazla',
      ],
    );
    expect(req.placements.any((p) => p.body == 'moon'), isFalse);
    expect(req.discoveryThemes, hasLength(3));
    expect(req.omittedLayers.any((l) => l.contains('ambiguous.moon')), isTrue);

    final json = jsonEncode(req.toProviderJson());
    for (final leak in const [
      'ownerId',
      'latitude',
      'longitude',
      'timezoneId',
      'utcInstantIso',
      'evidenceFingerprint',
      '1990-05-15',
    ]) {
      expect(json.contains(leak), isFalse, reason: leak);
    }
    expect(json.contains('"longitude"'), isFalse);
  });

  test('discovery themes do not mutate facts-only fingerprint', () {
    final a = YildiznameRequestFactory.fromEvidence(
      evidence: NarrativeEvidenceFixtures.fullNatal(),
      languageCode: 'en',
    );
    final b = YildiznameRequestFactory.fromEvidence(
      evidence: NarrativeEvidenceFixtures.fullNatal(),
      languageCode: 'en',
      observedRecurringLabels: const ['patience'],
    );
    expect(
      YildiznameRequestFingerprint.factsOnly(a),
      YildiznameRequestFingerprint.factsOnly(b),
    );
    expect(
      YildiznameRequestFingerprint.of(a),
      isNot(YildiznameRequestFingerprint.of(b)),
    );
  });
}
