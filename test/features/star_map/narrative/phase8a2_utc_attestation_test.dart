/// Phase 8A.2 — UTC instant attestation red-team (no provider).
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

  test('canonical builder UTC string → narrativeFull', () {
    final chart = phase8aChart(phase8aE4Profile());
    final iso = chart.natalEvidence!.metadata.utcInstantIso;
    expect(iso, isNotNull);
    expect(DateTime.parse(iso!).isUtc, isTrue);
    expect(_plan(chart).kind, YildiznameLivePlanKind.narrativeFull);
  });

  test('explicit Z UTC ISO → narrativeFull', () {
    final chart = phase8aMutateEvidence(
      phase8aChart(phase8aE4Profile()),
      utcInstantIso: '2000-01-01T09:00:00Z',
    );
    expect(_plan(chart).kind, YildiznameLivePlanKind.narrativeFull);
  });

  test('offset ISO parsed as UTC → narrativeFull', () {
    final chart = phase8aMutateEvidence(
      phase8aChart(phase8aE4Profile()),
      utcInstantIso: '2000-01-01T12:00:00+03:00',
    );
    expect(DateTime.parse('2000-01-01T12:00:00+03:00').isUtc, isTrue);
    expect(_plan(chart).kind, YildiznameLivePlanKind.narrativeFull);
  });

  test('no-offset ISO → invalidEvidence', () {
    final chart = phase8aMutateEvidence(
      phase8aChart(phase8aE4Profile()),
      utcInstantIso: '2000-01-01T12:00:00',
    );
    expect(DateTime.parse('2000-01-01T12:00:00').isUtc, isFalse);
    expect(_plan(chart).kind, YildiznameLivePlanKind.invalidEvidence);
  });

  test('malformed utcInstantIso → invalidEvidence', () {
    expect(
      _plan(phase8aMutateEvidence(
        phase8aChart(phase8aE4Profile()),
        utcInstantIso: 'not-a-valid-instant',
      )).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('empty utcInstantIso → invalidEvidence', () {
    expect(
      _plan(phase8aMutateEvidence(
        phase8aChart(phase8aE4Profile()),
        utcInstantIso: '',
      )).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });
}
