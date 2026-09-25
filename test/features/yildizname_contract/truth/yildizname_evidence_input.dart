/// Phase 2 — birth evidence input + E0–E4 classifier (test-only).
library;

import 'yildizname_contract_enums.dart';

class ContractEvidenceInput {
  const ContractEvidenceInput({
    this.birthDate,
    this.birthTime,
    this.timeKnown = false,
    this.place,
    this.latitude,
    this.longitude,
    this.timezoneId,
    this.timeUnknownConfirmed = false,
    this.usedSyntheticBirthTime = false,
    this.assumedDeviceTimezone = false,
    this.assumedDefaultPlace = false,
  });

  final DateTime? birthDate;
  final DateTime? birthTime;
  final bool timeKnown;
  final String? place;
  final double? latitude;
  final double? longitude;
  final String? timezoneId;
  final bool timeUnknownConfirmed;
  final bool usedSyntheticBirthTime;
  final bool assumedDeviceTimezone;
  final bool assumedDefaultPlace;

  bool get hasDate => birthDate != null;
  bool get hasTime => timeKnown && birthTime != null;
  bool get hasPlace =>
      (place != null && place!.trim().isNotEmpty) ||
      (latitude != null && longitude != null);
  bool get hasTimezone => timezoneId != null && timezoneId!.trim().isNotEmpty;
  bool get placeResolved => hasPlace && hasTimezone;
}

abstract final class YildiznameEvidenceClassifier {
  YildiznameEvidenceClassifier._();

  static ContractEvidenceState classify(ContractEvidenceInput i) {
    if (!i.hasDate) return ContractEvidenceState.e0;
    if (i.hasTime && i.placeResolved) return ContractEvidenceState.e4;
    if (i.hasTime && !i.placeResolved) return ContractEvidenceState.e3;
    if (!i.hasTime && i.hasPlace) return ContractEvidenceState.e2;
    return ContractEvidenceState.e1;
  }
}
