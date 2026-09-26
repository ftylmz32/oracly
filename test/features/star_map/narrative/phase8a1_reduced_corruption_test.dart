/// Phase 8A.1 — reduced evidence must not carry exact factual layers.
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

  test('inject longitude into intervalStable → invalidEvidence', () {
    final chart = phase8aInjectReducedExactField(
      phase8aChart(phase8aE2Profile()),
      longitude: 123.45,
    );
    expect(_plan(chart).kind, YildiznameLivePlanKind.invalidEvidence);
  });

  test('inject degreeWithinSign into intervalStable → invalidEvidence', () {
    final chart = phase8aInjectReducedExactField(
      phase8aChart(phase8aE2Profile()),
      degreeWithinSign: 12.3,
    );
    expect(_plan(chart).kind, YildiznameLivePlanKind.invalidEvidence);
  });

  test('inject retrograde into intervalStable → invalidEvidence', () {
    final chart = phase8aInjectReducedExactField(
      phase8aChart(phase8aE2Profile()),
      retrograde: true,
    );
    expect(_plan(chart).kind, YildiznameLivePlanKind.invalidEvidence);
  });

  test('inject house into intervalStable → invalidEvidence', () {
    final chart = phase8aInjectReducedExactField(
      phase8aChart(phase8aE2Profile()),
      house: 7,
    );
    expect(_plan(chart).kind, YildiznameLivePlanKind.invalidEvidence);
  });

  test('ambiguous placement with selected sign → invalidEvidence', () {
    final chart = phase8aInjectAmbiguousSign(phase8aChart(phase8aE2Profile()));
    expect(_plan(chart).kind, YildiznameLivePlanKind.invalidEvidence);
  });
}
