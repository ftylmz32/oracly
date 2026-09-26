/// Phase 8A.1 — top-level evidence metadata provenance red-team (no provider).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';

import 'phase8a_live_plan_support.dart';

YildiznameLivePlan _plan(BirthChart chart) => YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: 'owner-a',
      chart: chart,
      languageCode: 'tr',
    );

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  group('valid real calculator evidence', () {
    test('E2 → narrativeReduced', () {
      expect(
        _plan(phase8aChart(phase8aE2Profile())).kind,
        YildiznameLivePlanKind.narrativeReduced,
      );
    });

    test('E4 → narrativeFull', () {
      expect(
        _plan(phase8aChart(phase8aE4Profile())).kind,
        YildiznameLivePlanKind.narrativeFull,
      );
    });
  });

  group('metadata mutations → invalidEvidence', () {
    test('A blank engineId', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE2Profile()),
          engineId: '',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('B wrong engineId', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE2Profile()),
          engineId: 'other.engine',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('C blank engineVersion', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE2Profile()),
          engineVersion: '',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('D wrong engineVersion', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE2Profile()),
          engineVersion: '9.9.9',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('E wrong calculationVersion', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE2Profile()),
          calculationVersion: 'other-v1',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('F blank evidenceFingerprint', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE2Profile()),
          evidenceFingerprint: '',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('G stale evidenceFingerprint', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE2Profile()),
          evidenceFingerprint: 'stale-fingerprint-not-current',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('H wrong zodiacSystem', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE2Profile()),
          zodiacSystem: 'sidereal',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('I wrong coordinateConvention', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE2Profile()),
          coordinateConvention: 'mean_ecliptic',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('J missing timezoneDatabase', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE2Profile()),
          clearTimezoneDatabase: true,
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('J wrong timezoneDatabase', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE2Profile()),
          timezoneDatabase: 'other_tzdb',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('K wrong houseSystem contract (fact provenance)', () {
      // NatalHouseSystem is currently single-valued; wrong contract is enforced
      // via fact provenance.houseSystem disagreeing with metadata.
      expect(
        _plan(phase8aMutateFactProvenance(
          phase8aChart(phase8aE4Profile()),
          target: 'house',
          field: 'houseSystem',
          value: 'placidus',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('L reduced birthInstantKind != unknown_time_interval', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE2Profile()),
          birthInstantKind: 'exact',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('M full birthInstantKind != exact', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE4Profile()),
          birthInstantKind: 'unknown_time_interval',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('N full missing utcInstantIso', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE4Profile()),
          clearUtcInstantIso: true,
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });

    test('O full malformed utcInstantIso', () {
      expect(
        _plan(phase8aMutateEvidence(
          phase8aChart(phase8aE4Profile()),
          utcInstantIso: 'not-a-valid-instant',
        )).kind,
        YildiznameLivePlanKind.invalidEvidence,
      );
    });
  });

  test('corrupted evidence + valid owner → invalidEvidence', () {
    final plan = YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: 'owner-a',
      chart: phase8aMutateEvidence(
        phase8aChart(phase8aE4Profile()),
        engineVersion: '0.0.0',
      ),
      languageCode: 'tr',
    );
    expect(plan.kind, YildiznameLivePlanKind.invalidEvidence);
    expect(plan.request, isNull);
  });

  test('flag false + full evidence → legacyLocal', () {
    final plan = YildiznameLivePlanBuilder.build(
      featureEnabled: false,
      ownerId: 'owner-a',
      chart: phase8aChart(phase8aE4Profile()),
      languageCode: 'tr',
    );
    expect(plan.kind, YildiznameLivePlanKind.legacyLocal);
  });
}
