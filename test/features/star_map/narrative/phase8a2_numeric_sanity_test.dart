/// Phase 8A.2 — numeric bounds / NaN / infinity red-team (no provider).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';

import 'phase8a_live_plan_support.dart';
import 'phase8a2_json_mutate.dart';
import 'phase8a2_typed_mutate.dart';

YildiznameLivePlan _plan(BirthChart chart) => YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: 'owner-a',
      chart: chart,
      languageCode: 'tr',
    );

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  late BirthChart e4;

  setUp(() => e4 = phase8aChart(phase8aE4Profile()));

  test('longitude bounds / NaN / infinity → invalidEvidence', () {
    for (final v in [-0.1, 360.0, double.nan, double.infinity]) {
      expect(
        _plan(phase8aTypedPlacementLongitude(e4, v)).kind,
        YildiznameLivePlanKind.invalidEvidence,
        reason: '$v',
      );
    }
  });

  test('degree bounds / NaN / infinity → invalidEvidence', () {
    for (final v in [-0.1, 30.0, double.nan, double.infinity]) {
      expect(
        _plan(phase8aTypedPlacementDegree(e4, v)).kind,
        YildiznameLivePlanKind.invalidEvidence,
        reason: '$v',
      );
    }
  });

  test('house 0 / 13 → invalidEvidence', () {
    for (final h in [0, 13]) {
      expect(
        _plan(phase8aTypedPlacementHouse(e4, h)).kind,
        YildiznameLivePlanKind.invalidEvidence,
        reason: '$h',
      );
    }
  });

  test('cuspLongitude bounds / NaN / infinity → invalidEvidence', () {
    for (final v in [-1.0, 360.0, double.nan, double.infinity]) {
      expect(
        _plan(phase8aTypedHouseCusp(e4, v)).kind,
        YildiznameLivePlanKind.invalidEvidence,
        reason: '$v',
      );
    }
  });

  test('JSON path house out of range also rejected', () {
    expect(
      _plan(phase8aMutatePlacementField(e4, field: 'house', value: 0)).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });
}
