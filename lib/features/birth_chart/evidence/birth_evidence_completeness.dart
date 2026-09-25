/// Phase 3 — birth evidence completeness (production E0–E4).
library;

/// Maps 1:1 to Phase 2 ContractEvidenceState E0–E4.
enum BirthEvidenceCompleteness {
  /// E0 — no birth date.
  missingDate,

  /// E1 — date only.
  dateOnly,

  /// E2 — date + place/TZ, time unknown.
  dateAndPlaceNoTime,

  /// E3 — date + known time, place/TZ unresolved.
  dateAndTimeNoPlace,

  /// E4 — date + time + place + coords + timezoneId.
  /// Evidence complete — NOT full natal calculation (Phase 4).
  full,
}
