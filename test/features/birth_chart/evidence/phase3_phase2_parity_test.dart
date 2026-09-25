/// Task 40 — production completeness ↔ Phase 2 ContractEvidenceState.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence_completeness.dart';

import '../../yildizname_contract/truth/yildizname_contract_enums.dart';

ContractEvidenceState toContract(BirthEvidenceCompleteness c) => switch (c) {
      BirthEvidenceCompleteness.missingDate => ContractEvidenceState.e0,
      BirthEvidenceCompleteness.dateOnly => ContractEvidenceState.e1,
      BirthEvidenceCompleteness.dateAndPlaceNoTime => ContractEvidenceState.e2,
      BirthEvidenceCompleteness.dateAndTimeNoPlace => ContractEvidenceState.e3,
      BirthEvidenceCompleteness.full => ContractEvidenceState.e4,
    };

BirthEvidenceCompleteness fromContract(ContractEvidenceState e) => switch (e) {
      ContractEvidenceState.e0 => BirthEvidenceCompleteness.missingDate,
      ContractEvidenceState.e1 => BirthEvidenceCompleteness.dateOnly,
      ContractEvidenceState.e2 => BirthEvidenceCompleteness.dateAndPlaceNoTime,
      ContractEvidenceState.e3 => BirthEvidenceCompleteness.dateAndTimeNoPlace,
      ContractEvidenceState.e4 => BirthEvidenceCompleteness.full,
    };

void main() {
  test('Task 40 exact parity missingDate↔e0 … full↔e4', () {
    const pairs = <(BirthEvidenceCompleteness, ContractEvidenceState)>[
      (BirthEvidenceCompleteness.missingDate, ContractEvidenceState.e0),
      (BirthEvidenceCompleteness.dateOnly, ContractEvidenceState.e1),
      (BirthEvidenceCompleteness.dateAndPlaceNoTime, ContractEvidenceState.e2),
      (BirthEvidenceCompleteness.dateAndTimeNoPlace, ContractEvidenceState.e3),
      (BirthEvidenceCompleteness.full, ContractEvidenceState.e4),
    ];
    for (final (prod, contract) in pairs) {
      expect(toContract(prod), contract);
      expect(fromContract(contract), prod);
    }
    expect(BirthEvidenceCompleteness.values.length, 5);
    expect(ContractEvidenceState.values.length, 5);
  });
}
