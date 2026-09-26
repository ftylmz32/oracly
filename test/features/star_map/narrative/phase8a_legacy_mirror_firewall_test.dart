/// Phase 8A — legacy BirthChart mirrors must never become Narrative facts.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';

import 'phase8a_live_plan_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('O tropical chart with natalEvidence null → legacyLocal (no request)', () {
    final chart = phase8aChart(phase8aE1Profile());
    expect(chart.fidelity, ChartCalculationFidelity.tropicalSunSign);
    expect(chart.natalEvidence, isNull);

    final plan = YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: 'owner-a',
      chart: chart,
      languageCode: 'tr',
    );
    expect(plan.kind, YildiznameLivePlanKind.legacyLocal);
    expect(plan.request, isNull);
    expect(plan.requestFingerprint, isNull);
  });

  test('placeholder degree/house on sun never enters a Narrative request', () {
    final base = phase8aChart(phase8aE1Profile());
    final json = Map<String, dynamic>.from(base.toJson());
    final sun = Map<String, dynamic>.from(json['sun'] as Map);
    sun['degree'] = 0;
    sun['house'] = 0;
    json['sun'] = sun;
    json['natalEvidence'] = null;
    json['fidelity'] = ChartCalculationFidelity.tropicalSunSign.name;
    final hostile = BirthChart.fromJson(json);

    expect(hostile.natalEvidence, isNull);
    expect(hostile.sun.degree, 0);
    expect(hostile.sun.house, 0);

    final plan = YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: 'owner-a',
      chart: hostile,
      languageCode: 'tr',
    );
    expect(plan.kind, YildiznameLivePlanKind.legacyLocal);
    expect(plan.request, isNull);
  });

  test('M reduced Narrative request has no degree/house/Asc/MC', () {
    final plan = YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: 'owner-a',
      chart: phase8aChart(phase8aE2Profile()),
      languageCode: 'tr',
    );
    expect(plan.kind, YildiznameLivePlanKind.narrativeReduced);
    final req = plan.request!;
    for (final p in req.placements) {
      expect(p.degreeWithinSign, isNull);
      expect(p.house, isNull);
      expect(p.retrograde, isNull);
    }
    expect(req.angles, isEmpty);
    expect(req.houses, isEmpty);
    expect(req.aspects, isEmpty);
  });
}
