/// Phase 8A.1 — fact-level provenance must match evidence envelope (no provider).
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

  test('REDUCED: one placement evidenceFingerprint differs → invalidEvidence',
      () {
    final chart = phase8aMutateFactProvenance(
      phase8aChart(phase8aE2Profile()),
      target: 'placement',
      field: 'evidenceFingerprint',
      value: 'fact-fp-does-not-match-envelope',
    );
    expect(_plan(chart).kind, YildiznameLivePlanKind.invalidEvidence);
  });

  test('FULL: one placement engineVersion differs → invalidEvidence', () {
    final chart = phase8aMutateFactProvenance(
      phase8aChart(phase8aE4Profile()),
      target: 'placement',
      field: 'engineVersion',
      value: '0.0.1',
    );
    expect(_plan(chart).kind, YildiznameLivePlanKind.invalidEvidence);
  });

  test('FULL: Ascendant calculationVersion differs → invalidEvidence', () {
    final chart = phase8aMutateFactProvenance(
      phase8aChart(phase8aE4Profile()),
      target: 'ascendant',
      field: 'calculationVersion',
      value: 'yildizname-natal-v0',
    );
    expect(_plan(chart).kind, YildiznameLivePlanKind.invalidEvidence);
  });

  test('FULL: one house provenance differs → invalidEvidence', () {
    final chart = phase8aMutateFactProvenance(
      phase8aChart(phase8aE4Profile()),
      target: 'house',
      field: 'engineId',
      value: 'tampered.engine',
    );
    expect(_plan(chart).kind, YildiznameLivePlanKind.invalidEvidence);
  });

  test('FULL: one aspect provenance differs → invalidEvidence', () {
    final chart = phase8aMutateFactProvenance(
      phase8aChart(phase8aE4Profile()),
      target: 'aspect',
      field: 'zodiacSystem',
      value: 'sidereal',
    );
    expect(_plan(chart).kind, YildiznameLivePlanKind.invalidEvidence);
  });
}
