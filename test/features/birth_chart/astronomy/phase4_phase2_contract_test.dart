/// Phase 4 — production structured evidence → Phase 2 contract adapter (test-only).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/astronomical_fact_certainty.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/birth_chart/astronomy/evidence_aware_natal_calculator.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';

import '../../yildizname_contract/truth/yildizname_contract_enums.dart';

ContractFactCertainty mapCertainty(AstronomicalFactCertainty c) =>
    ContractFactCertainty.values.byName(c.name);

ContractFidelity mapFidelity(ChartCalculationFidelity f) =>
    ContractFidelity.values.byName(f.name);

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('certainty + fidelity enum parity with Phase 2', () {
    for (final c in AstronomicalFactCertainty.values) {
      expect(mapCertainty(c).name, c.name);
    }
    for (final f in ChartCalculationFidelity.values) {
      expect(mapFidelity(f).name, f.name);
    }
  });

  test('E4 production chart maps to fullNatalEphemeris contract fidelity', () {
    final chart = EvidenceAwareNatalChartCalculator().calculate(BirthProfile(
      birthDate: DateTime(2000, 1, 1),
      birthPlace: 'İstanbul',
      birthTime: DateTime(2000, 1, 1, 12),
      birthTimeKnown: true,
      latitude: 41.0082,
      longitude: 28.9784,
      timezoneId: 'Europe/Istanbul',
      timezoneResolutionStatus: BirthTimezoneStatus.resolved,
    ));
    expect(mapFidelity(chart.fidelity), ContractFidelity.fullNatalEphemeris);
    expect(chart.natalEvidence, isNotNull);
    for (final p in chart.natalEvidence!.placements) {
      expect(mapCertainty(p.certainty), ContractFactCertainty.exact);
    }
  });
}
