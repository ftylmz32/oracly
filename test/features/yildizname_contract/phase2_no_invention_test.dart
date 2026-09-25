/// Phase 2 — no invented facts or assumed evidence.
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixtures/candidate_chart_fixtures.dart';
import 'fixtures/evidence_fixtures.dart';
import 'truth/yildizname_candidate_chart.dart';
import 'truth/yildizname_contract_enums.dart';
import 'truth/yildizname_truth_oracle.dart';

void main() {
  group('invented facts FAIL', () {
    test('inventedMoonE1 FAIL', () {
      final r = YildiznameTruthOracle.validate(
        CandidateChartFixtures.inventedMoonE1(),
      );
      expect(r.isFail, isTrue);
    });

    test('inventedAscE2 FAIL', () {
      final r = YildiznameTruthOracle.validate(
        CandidateChartFixtures.inventedAscE2(),
      );
      expect(r.isFail, isTrue);
    });

    test('e3WithAsc FAIL (asc without place resolution)', () {
      final r = YildiznameTruthOracle.validate(
        CandidateChartFixtures.e3WithAsc(),
      );
      expect(r.isFail, isTrue);
    });

    test('noonDefault synthetic birth time FAIL', () {
      final r = YildiznameTruthOracle.validate(
        CandidateChartFixtures.noonDefault(),
      );
      expect(r.isFail, isTrue);
    });
  });

  group('assumed evidence flags FAIL', () {
    test('device timezone used FAIL', () {
      final chart = ContractCandidateChart(
        evidence: EvidenceFixtures.e1,
        evidenceState: ContractEvidenceState.e1,
        owner: ContractOwner.anonymousLocal,
        scope: ContractScope.legacy,
        fidelity: ContractFidelity.tropicalSunSign,
        facts: [CandidateChartFixtures.sunLegacy('Cancer')],
        unavailableLayers: const ['moon', 'ascendant', 'houses'],
        deviceTimezoneUsed: true,
      );
      final r = YildiznameTruthOracle.validate(chart);
      expect(r.isFail, isTrue);
    });

    test('assumed place used FAIL', () {
      final chart = ContractCandidateChart(
        evidence: EvidenceFixtures.e1,
        evidenceState: ContractEvidenceState.e1,
        owner: ContractOwner.anonymousLocal,
        scope: ContractScope.legacy,
        fidelity: ContractFidelity.tropicalSunSign,
        facts: [CandidateChartFixtures.sunLegacy('Cancer')],
        unavailableLayers: const ['moon', 'ascendant', 'houses'],
        assumedPlaceUsed: true,
      );
      final r = YildiznameTruthOracle.validate(chart);
      expect(r.isFail, isTrue);
    });
  });
}
