/// Phase 2 — fact certainty matrix cells via oracle.
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixtures/candidate_chart_fixtures.dart';
import 'fixtures/evidence_fixtures.dart';
import 'truth/yildizname_candidate_chart.dart';
import 'truth/yildizname_candidate_fact.dart';
import 'truth/yildizname_contract_enums.dart';
import 'truth/yildizname_fact_matrix.dart';
import 'truth/yildizname_truth_oracle.dart';

void main() {
  group('matrix cells', () {
    test('sun identity allowed at e1 with exact + tropical', () {
      final cell = YildiznameFactMatrix.cell(
        ContractFactType.sunIdentity,
        ContractEvidenceState.e1,
      );
      expect(cell.allowed, isTrue);
      expect(cell.requiredFidelity, ContractFidelity.tropicalSunSign);
      expect(cell.allowedCertainty, contains(ContractFactCertainty.exact));
    });

    test('moon at e2 allows intervalStable', () {
      final cell = YildiznameFactMatrix.cell(
        ContractFactType.moon,
        ContractEvidenceState.e2,
      );
      expect(cell.allowed, isTrue);
      expect(
        cell.allowedCertainty,
        contains(ContractFactCertainty.intervalStable),
      );
    });

    test('ascendant at e2 not allowed for exact', () {
      final cell = YildiznameFactMatrix.cell(
        ContractFactType.ascendant,
        ContractEvidenceState.e2,
      );
      expect(cell.allowed, isFalse);
    });

    test('houses at e1 not allowed', () {
      final cell = YildiznameFactMatrix.cell(
        ContractFactType.houses,
        ContractEvidenceState.e1,
      );
      expect(cell.allowed, isFalse);
    });
  });

  group('oracle enforcement', () {
    test('Asc+E2+exact FAIL', () {
      final r = YildiznameTruthOracle.validate(
        CandidateChartFixtures.inventedAscE2(),
      );
      expect(r.isFail, isTrue);
    });

    test('Moon+E2+intervalStable PASS', () {
      final r = YildiznameTruthOracle.validate(
        CandidateChartFixtures.e2ReducedSuccess(),
      );
      expect(r.isPass, isTrue, reason: r.reason);
    });

    test('House+E1 FAIL', () {
      final chart = ContractCandidateChart(
        evidence: EvidenceFixtures.e1,
        evidenceState: ContractEvidenceState.e1,
        owner: ContractOwner.anonymousLocal,
        scope: ContractScope.legacy,
        fidelity: ContractFidelity.tropicalSunSign,
        facts: [
          CandidateChartFixtures.sunLegacy('Cancer'),
          const ContractCandidateFact(
            type: ContractFactType.houses,
            certainty: ContractFactCertainty.exact,
            fidelity: ContractFidelity.fullNatalEphemeris,
            value: '1-12',
          ),
        ],
        unavailableLayers: const ['moon'],
      );
      final r = YildiznameTruthOracle.validate(chart);
      expect(r.isFail, isTrue);
    });

    test('Sun+E1+legacy PASS', () {
      final r = YildiznameTruthOracle.validate(
        CandidateChartFixtures.e1ReducedSuccess(),
      );
      expect(r.isPass, isTrue, reason: r.reason);
    });
  });
}
