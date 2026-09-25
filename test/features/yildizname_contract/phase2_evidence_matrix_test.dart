/// Phase 2 — evidence matrix: E0–E4 classification.
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixtures/evidence_fixtures.dart';
import 'truth/yildizname_contract_enums.dart';
import 'truth/yildizname_evidence_input.dart';

void main() {
  group('EvidenceFixtures classify E0–E4', () {
    test('e0 has no date', () {
      expect(
        YildiznameEvidenceClassifier.classify(EvidenceFixtures.e0),
        ContractEvidenceState.e0,
      );
    });

    test('e1 date only', () {
      expect(
        YildiznameEvidenceClassifier.classify(EvidenceFixtures.e1),
        ContractEvidenceState.e1,
      );
    });

    test('e2 date + place, time unknown', () {
      expect(
        YildiznameEvidenceClassifier.classify(EvidenceFixtures.e2),
        ContractEvidenceState.e2,
      );
    });

    test('e3 date + time, place unresolved', () {
      expect(
        YildiznameEvidenceClassifier.classify(EvidenceFixtures.e3),
        ContractEvidenceState.e3,
      );
    });

    test('e4 date + time + place + timezone', () {
      expect(
        YildiznameEvidenceClassifier.classify(EvidenceFixtures.e4),
        ContractEvidenceState.e4,
      );
    });

    test('e3MissingTz is E3 not E4', () {
      final state = YildiznameEvidenceClassifier.classify(
        EvidenceFixtures.e3MissingTz,
      );
      expect(state, ContractEvidenceState.e3);
      expect(state, isNot(ContractEvidenceState.e4));
      expect(EvidenceFixtures.e3MissingTz.hasPlace, isTrue);
      expect(EvidenceFixtures.e3MissingTz.hasTimezone, isFalse);
      expect(EvidenceFixtures.e3MissingTz.placeResolved, isFalse);
    });

    test('timezoneMissing mirrors e3MissingTz', () {
      expect(
        YildiznameEvidenceClassifier.classify(EvidenceFixtures.timezoneMissing),
        ContractEvidenceState.e3,
      );
    });
  });

  group('legal evidence combos', () {
    test('time without date stays e0', () {
      final i = ContractEvidenceInput(
        birthTime: DateTime(1990, 7, 15, 14, 30),
        timeKnown: true,
      );
      expect(
        YildiznameEvidenceClassifier.classify(i),
        ContractEvidenceState.e0,
      );
    });

    test('place without date stays e0', () {
      const i = ContractEvidenceInput(place: 'Istanbul', timezoneId: 'Europe/Istanbul');
      expect(
        YildiznameEvidenceClassifier.classify(i),
        ContractEvidenceState.e0,
      );
    });

    test('date + time + place without tz is e3', () {
      expect(
        EvidenceFixtures.e3MissingTz.hasTime,
        isTrue,
      );
      expect(
        YildiznameEvidenceClassifier.classify(EvidenceFixtures.e3MissingTz),
        ContractEvidenceState.e3,
      );
    });
  });
}
