/// Phase 8A.2 — FULL structural shape red-team (no astronomy recompute).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_body.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';

import 'phase8a_live_plan_support.dart';
import 'phase8a2_json_mutate.dart';

YildiznameLivePlan _plan(BirthChart chart) => YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: 'owner-a',
      chart: chart,
      languageCode: 'tr',
    );

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  late BirthChart e4;

  setUp(() {
    e4 = phase8aChart(phase8aE4Profile());
    expect(e4.natalEvidence!.placements, hasLength(NatalBody.values.length));
    expect(e4.natalEvidence!.aspects, isNotEmpty);
  });

  test('canonical E4 → narrativeFull', () {
    expect(_plan(e4).kind, YildiznameLivePlanKind.narrativeFull);
  });

  test('A placement certainty intervalStable → invalidEvidence', () {
    expect(
      _plan(phase8aMutatePlacementField(
        e4,
        field: 'certainty',
        value: 'intervalStable',
      )).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('B–E remove exact placement fields → invalidEvidence', () {
    for (final field in ['degreeWithinSign', 'longitude', 'house']) {
      expect(
        _plan(phase8aMutatePlacementField(e4, field: field, remove: true)).kind,
        YildiznameLivePlanKind.invalidEvidence,
        reason: field,
      );
    }
    // Sun/Moon intentionally omit retrograde; corrupt a planet stamp.
    final i = e4.natalEvidence!.placements
        .indexWhere((p) => p.retrograde != null);
    expect(i, greaterThanOrEqualTo(0));
    expect(
      _plan(phase8aMutatePlacementField(
        e4,
        field: 'retrograde',
        remove: true,
        index: i,
      )).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('F duplicate NatalBody → invalidEvidence', () {
    expect(
      _plan(phase8aDuplicateBody(e4)).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('G Ascendant removed → invalidEvidence', () {
    expect(
      _plan(phase8aRemoveAscendant(e4)).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('H Ascendant kind changed → invalidEvidence', () {
    expect(
      _plan(phase8aMutateAngle(
        e4,
        target: 'ascendant',
        field: 'kind',
        value: 'midheaven',
      )).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('I Ascendant certainty changed → invalidEvidence', () {
    expect(
      _plan(phase8aMutateAngle(
        e4,
        target: 'ascendant',
        field: 'certainty',
        value: 'ambiguous',
      )).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('J MC removed → invalidEvidence', () {
    expect(
      _plan(phase8aRemoveMidheaven(e4)).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('K MC certainty changed → invalidEvidence', () {
    expect(
      _plan(phase8aMutateAngle(
        e4,
        target: 'midheaven',
        field: 'certainty',
        value: 'unavailable',
      )).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('L 11 houses → invalidEvidence', () {
    expect(
      _plan(phase8aTrimHouses(e4, 11)).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('M duplicate house number → invalidEvidence', () {
    expect(
      _plan(phase8aDuplicateHouseNumber(e4)).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('N house certainty not exact → invalidEvidence', () {
    expect(
      _plan(phase8aMutateHouseField(
        e4,
        field: 'certainty',
        value: 'ambiguous',
      )).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('O aspect certainty not exact → invalidEvidence', () {
    expect(
      _plan(phase8aMutateAspectField(
        e4,
        field: 'certainty',
        value: 'ambiguous',
      )).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('P aspect bodyA == bodyB → invalidEvidence', () {
    final body = e4.natalEvidence!.aspects.first.bodyA.name;
    expect(
      _plan(phase8aMutateAspectField(e4, field: 'bodyB', value: body)).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('Q negative aspect orb → invalidEvidence', () {
    expect(
      _plan(phase8aMutateAspectField(e4, field: 'orb', value: -0.5)).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('R negative balance count → invalidEvidence', () {
    expect(
      _plan(phase8aNegativeElement(e4)).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('legacy E0/E1/E3 + flag false unchanged', () {
    expect(
      YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: 'a',
        chart: null,
        languageCode: 'tr',
      ).kind,
      YildiznameLivePlanKind.legacyLocal,
    );
    for (final p in [phase8aE1Profile(), phase8aE3Profile()]) {
      expect(
        _plan(phase8aChart(p)).kind,
        YildiznameLivePlanKind.legacyLocal,
      );
    }
    expect(
      YildiznameLivePlanBuilder.build(
        featureEnabled: false,
        ownerId: 'a',
        chart: e4,
        languageCode: 'tr',
      ).kind,
      YildiznameLivePlanKind.legacyLocal,
    );
  });
}
