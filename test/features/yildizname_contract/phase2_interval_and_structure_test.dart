/// Phase 2 — interval classification + placement/aspect structure (Tasks 8, 33–36).
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixtures/candidate_chart_fixtures.dart';
import 'fixtures/evidence_fixtures.dart';
import 'truth/yildizname_candidate_chart.dart';
import 'truth/yildizname_candidate_fact.dart';
import 'truth/yildizname_contract_enums.dart';
import 'truth/yildizname_interval.dart';
import 'truth/yildizname_structure_validators.dart';
import 'truth/yildizname_truth_oracle.dart';

void main() {
  group('interval oracle (Task 8)', () {
    test('stable interval returns first value', () {
      const samples = [
        IntervalSample(label: 'start', value: 'Cancer'),
        IntervalSample(label: 'mid', value: 'Cancer'),
        IntervalSample(label: 'end', value: 'Cancer'),
      ];
      expect(
        YildiznameIntervalOracle.classify(samples),
        ContractFactCertainty.intervalStable,
      );
      expect(YildiznameIntervalOracle.chosenValue(samples), 'Cancer');
    });

    test('ambiguous never picks noon/midpoint', () {
      const samples = [
        IntervalSample(label: '00:00', value: 'Cancer'),
        IntervalSample(label: '12:00', value: 'Leo'),
        IntervalSample(label: '23:59', value: 'Leo'),
      ];
      expect(
        YildiznameIntervalOracle.classify(samples),
        ContractFactCertainty.ambiguous,
      );
      expect(YildiznameIntervalOracle.chosenValue(samples), isNull);
    });

    test('empty samples → unavailable', () {
      expect(
        YildiznameIntervalOracle.classify(const []),
        ContractFactCertainty.unavailable,
      );
    });
  });

  group('placement / aspect structure (Tasks 33–35)', () {
    const prov = ContractProvenance(
      engineId: 'test',
      engineVersion: '0',
      evidenceFingerprint: 'ev',
      fidelity: ContractFidelity.fullNatalEphemeris,
    );

    test('valid placement PASS', () {
      final r = YildiznameStructureValidators.placement(
        const ContractPlacement(
          body: 'Moon',
          longitude: 45.0,
          signIndex: 1,
          degreeWithinSign: 15.0,
          certainty: ContractFactCertainty.exact,
          house: 4,
          provenance: prov,
        ),
      );
      expect(r.isPass, isTrue, reason: r.reason);
    });

    test('sign/longitude mismatch FAIL', () {
      final r = YildiznameStructureValidators.placement(
        const ContractPlacement(
          body: 'Moon',
          longitude: 45.0,
          signIndex: 0,
          degreeWithinSign: 15.0,
          certainty: ContractFactCertainty.intervalStable,
        ),
      );
      expect(r.isFail, isTrue);
    });

    test('self-aspect and bad orb FAIL', () {
      expect(
        YildiznameStructureValidators.aspect(
          const ContractAspect(
            bodyA: 'Sun',
            bodyB: 'Sun',
            type: 'conjunction',
            orb: 1,
            certainty: ContractFactCertainty.exact,
          ),
        ).isFail,
        isTrue,
      );
      expect(
        YildiznameStructureValidators.aspect(
          const ContractAspect(
            bodyA: 'Sun',
            bodyB: 'Moon',
            type: 'square',
            orb: -1,
            certainty: ContractFactCertainty.exact,
          ),
        ).isFail,
        isTrue,
      );
    });
  });

  group('house system required (Task 36)', () {
    test('house placement without houseSystem FAIL', () {
      final chart = ContractCandidateChart(
        evidence: EvidenceFixtures.e4,
        evidenceState: ContractEvidenceState.e4,
        owner: ContractOwner.anonymousLocal,
        scope: ContractScope.reduced,
        fidelity: ContractFidelity.tropicalSunSign,
        facts: [CandidateChartFixtures.sunLegacy('Cancer')],
        placements: const [
          ContractPlacement(
            body: 'Sun',
            longitude: 120,
            signIndex: 4,
            degreeWithinSign: 0,
            certainty: ContractFactCertainty.unsupported,
            house: 5,
          ),
        ],
        unavailableLayers: const ['ascendant'],
        engineCapable: false,
      );
      final r = YildiznameTruthOracle.validate(chart);
      expect(r.isFail, isTrue);
    });
  });
}
