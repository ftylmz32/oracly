/// Phase 2 — reduced / legacy scope success without full natal.
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixtures/candidate_chart_fixtures.dart';
import 'truth/yildizname_contract_enums.dart';
import 'truth/yildizname_truth_oracle.dart';

void main() {
  test('e1ReducedSuccess PASS — legacy sun only', () {
    final chart = CandidateChartFixtures.e1ReducedSuccess();
    expect(chart.scope, ContractScope.legacy);
    expect(chart.fidelity, ContractFidelity.tropicalSunSign);
    expect(chart.unavailableLayers, isNotEmpty);
    final r = YildiznameTruthOracle.validate(chart);
    expect(r.isPass, isTrue, reason: r.reason);
  });

  test('e2ReducedSuccess PASS — interval moon, asc unavailable', () {
    final chart = CandidateChartFixtures.e2ReducedSuccess();
    expect(chart.scope, ContractScope.reduced);
    expect(chart.fidelity, ContractFidelity.reducedNatal);
    expect(chart.unavailableLayers, contains('ascendant'));
    expect(chart.unavailableLayers, contains('houses'));
    final r = YildiznameTruthOracle.validate(chart);
    expect(r.isPass, isTrue, reason: r.reason);
  });

  test('full natal NOT required for reduced success', () {
    for (final chart in [
      CandidateChartFixtures.e1ReducedSuccess(),
      CandidateChartFixtures.e2ReducedSuccess(),
    ]) {
      expect(chart.scope, isNot(ContractScope.full));
      expect(chart.fidelity, isNot(ContractFidelity.fullNatalEphemeris));
      expect(chart.engineCapable, isFalse);
      final r = YildiznameTruthOracle.validate(chart);
      expect(r.isPass, isTrue, reason: r.reason);
    }
  });
}
