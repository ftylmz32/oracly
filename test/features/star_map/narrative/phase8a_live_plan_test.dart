/// Phase 8A — live plan eligibility matrix (no provider).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_fingerprint.dart';

import 'phase8a_live_plan_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  group('feature flag', () {
    test('A/B/C flag false → always legacyLocal', () {
      for (final chart in [
        null,
        phase8aChart(phase8aE2Profile()),
        phase8aChart(phase8aE4Profile()),
      ]) {
        final plan = YildiznameLivePlanBuilder.build(
          featureEnabled: false,
          ownerId: 'owner-a',
          chart: chart,
          languageCode: 'tr',
        );
        expect(plan.kind, YildiznameLivePlanKind.legacyLocal);
        expect(plan.request, isNull);
      }
    });
  });

  group('evidence eligibility', () {
    test('D/E flag true + tropical (E1/E3) → legacyLocal', () {
      for (final p in [phase8aE1Profile(), phase8aE3Profile()]) {
        final chart = phase8aChart(p);
        expect(chart.natalEvidence, isNull);
        final plan = YildiznameLivePlanBuilder.build(
          featureEnabled: true,
          ownerId: 'owner-a',
          chart: chart,
          languageCode: 'tr',
        );
        expect(plan.kind, YildiznameLivePlanKind.legacyLocal);
      }
    });

    test('F flag true + valid reduced + owner → narrativeReduced', () {
      final chart = phase8aChart(phase8aE2Profile());
      expect(chart.fidelity, ChartCalculationFidelity.reducedNatal);
      final plan = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: 'owner-a',
        chart: chart,
        languageCode: 'tr',
      );
      expect(plan.kind, YildiznameLivePlanKind.narrativeReduced);
      expect(plan.scope, YildiznameNarrativeScope.reduced);
      expect(plan.request, isNotNull);
      expect(plan.request!.placements, isNotEmpty);
      for (final p in plan.request!.placements) {
        expect(p.degreeWithinSign, isNull);
        expect(p.house, isNull);
      }
      expect(plan.request!.angles, isEmpty);
      expect(plan.request!.houses, isEmpty);
    });

    test('G flag true + valid full + owner → narrativeFull', () {
      final chart = phase8aChart(phase8aE4Profile());
      expect(chart.fidelity, ChartCalculationFidelity.fullNatalEphemeris);
      final plan = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: 'owner-a',
        chart: chart,
        languageCode: 'EN',
      );
      expect(plan.kind, YildiznameLivePlanKind.narrativeFull);
      expect(plan.languageCode, 'en');
      expect(plan.scope, YildiznameNarrativeScope.full);
      expect(plan.request!.placements, isNotEmpty);
      expect(plan.evidenceFingerprint, isNotEmpty);
    });

    test('E0 null chart → legacyLocal', () {
      final plan = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: 'owner-a',
        chart: null,
        languageCode: 'tr',
      );
      expect(plan.kind, YildiznameLivePlanKind.legacyLocal);
    });
  });

  group('stale / invalid', () {
    test('J fidelity mismatch → invalidEvidence', () {
      final chart = phase8aMutateEvidence(
        phase8aChart(phase8aE2Profile()),
        chartFidelity: ChartCalculationFidelity.fullNatalEphemeris,
      );
      final plan = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: 'owner-a',
        chart: chart,
        languageCode: 'tr',
      );
      expect(plan.kind, YildiznameLivePlanKind.invalidEvidence);
    });

    test('K stale evidence fingerprint → invalidEvidence', () {
      final chart = phase8aMutateEvidence(
        phase8aChart(phase8aE2Profile()),
        evidenceFingerprint: 'stale-fingerprint-not-current',
      );
      final plan = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: 'owner-a',
        chart: chart,
        languageCode: 'tr',
      );
      expect(plan.kind, YildiznameLivePlanKind.invalidEvidence);
    });

    test('L stale calc version → invalidEvidence', () {
      final chart = phase8aMutateEvidence(
        phase8aChart(phase8aE4Profile()),
        calculationVersion: 'ancient-calc-v0',
      );
      final plan = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: 'owner-a',
        chart: chart,
        languageCode: 'tr',
      );
      expect(plan.kind, YildiznameLivePlanKind.invalidEvidence);
    });
  });

  group('determinism / themes / fingerprints', () {
    test('T same inputs → identical plan/request/fingerprints', () {
      final chart = phase8aChart(phase8aE2Profile());
      YildiznameLivePlan build() => YildiznameLivePlanBuilder.build(
            featureEnabled: true,
            ownerId: 'owner-a',
            chart: chart,
            languageCode: 'tr',
            personalDiscoveryLabels: const ['Sabır'],
          );
      final a = build();
      final b = build();
      expect(a, b);
      expect(a.requestFingerprint, b.requestFingerprint);
      expect(a.factsOnlyFingerprint, b.factsOnlyFingerprint);
    });

    test('R PD themes change full FP but not facts-only', () {
      final chart = phase8aChart(phase8aE2Profile());
      final bare = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: 'owner-a',
        chart: chart,
        languageCode: 'tr',
      );
      final withPd = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: 'owner-a',
        chart: chart,
        languageCode: 'tr',
        personalDiscoveryLabels: const ['Sabır', 'Odak'],
      );
      expect(bare.factsOnlyFingerprint, withPd.factsOnlyFingerprint);
      expect(bare.requestFingerprint, isNot(withPd.requestFingerprint));
      expect(
        withPd.factsOnlyFingerprint,
        YildiznameRequestFingerprint.factsOnly(withPd.request!),
      );
    });

    test('Q verified artifact recurrence precedes PD fill', () {
      final chart = phase8aChart(phase8aE2Profile());
      final history = [
        phase8aNarrativeArtifact(
          ownerId: 'owner-a',
          id: 'yid_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          label: 'Sabır',
          at: DateTime.utc(2026, 1, 1),
          semantic: 's1',
        ),
        phase8aNarrativeArtifact(
          ownerId: 'owner-a',
          id: 'yid_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          label: 'Sabır',
          at: DateTime.utc(2026, 2, 1),
          semantic: 's2',
        ),
      ];
      final plan = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: 'owner-a',
        chart: chart,
        languageCode: 'tr',
        artifactHistory: history,
        personalDiscoveryLabels: const ['YalnızPD'],
      );
      final labels = plan.request!.discoveryThemes.map((t) => t.label).toList();
      expect(labels.first, 'Sabır');
      expect(labels, contains('YalnızPD'));
      expect(labels.length, lessThanOrEqualTo(3));
    });
  });
}
