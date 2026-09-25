/// Phase 2 — evidence fixtures (test-only).
library;

import '../truth/yildizname_evidence_input.dart';

abstract final class EvidenceFixtures {
  EvidenceFixtures._();

  static final date = DateTime(1990, 7, 15);

  static const e0 = ContractEvidenceInput();

  static final e1 = ContractEvidenceInput(birthDate: date);

  static final e2 = ContractEvidenceInput(
    birthDate: date,
    place: 'Istanbul',
    latitude: 41.0,
    longitude: 29.0,
    timezoneId: 'Europe/Istanbul',
    timeUnknownConfirmed: true,
  );

  static final e3 = ContractEvidenceInput(
    birthDate: date,
    birthTime: DateTime(1990, 7, 15, 14, 30),
    timeKnown: true,
  );

  static final e4 = ContractEvidenceInput(
    birthDate: date,
    birthTime: DateTime(1990, 7, 15, 14, 30),
    timeKnown: true,
    place: 'Istanbul',
    latitude: 41.0,
    longitude: 29.0,
    timezoneId: 'Europe/Istanbul',
  );

  static final e3MissingTz = ContractEvidenceInput(
    birthDate: date,
    birthTime: DateTime(1990, 7, 15, 14, 30),
    timeKnown: true,
    place: 'Istanbul',
    latitude: 41.0,
    longitude: 29.0,
  );

  static final timezoneMissing = ContractEvidenceInput(
    birthDate: date,
    birthTime: DateTime(1990, 7, 15, 14, 30),
    timeKnown: true,
    place: 'Istanbul',
    latitude: 41.0,
    longitude: 29.0,
  );
}
