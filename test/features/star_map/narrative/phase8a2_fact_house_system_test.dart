/// Phase 8A.2 — fact provenance houseSystem must be wholeSign (no provider).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
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

  test('canonical E2/E4 still eligible', () {
    expect(
      _plan(phase8aChart(phase8aE2Profile())).kind,
      YildiznameLivePlanKind.narrativeReduced,
    );
    expect(
      _plan(phase8aChart(phase8aE4Profile())).kind,
      YildiznameLivePlanKind.narrativeFull,
    );
  });

  test('E2: null placement houseSystem → invalidEvidence', () {
    expect(
      _plan(phase8aClearFactHouseSystem(
        phase8aChart(phase8aE2Profile()),
        target: 'placement',
      )).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });

  test('E4: null houseSystem on placement/asc/mc/aspect → invalidEvidence', () {
    final e4 = phase8aChart(phase8aE4Profile());
    for (final target in ['placement', 'ascendant', 'midheaven', 'aspect']) {
      expect(
        _plan(phase8aClearFactHouseSystem(e4, target: target)).kind,
        YildiznameLivePlanKind.invalidEvidence,
        reason: target,
      );
    }
  });

  test('wrong fact houseSystem → invalidEvidence', () {
    expect(
      _plan(phase8aMutateFactProvenance(
        phase8aChart(phase8aE4Profile()),
        target: 'placement',
        field: 'houseSystem',
        value: 'placidus',
      )).kind,
      YildiznameLivePlanKind.invalidEvidence,
    );
  });
}
