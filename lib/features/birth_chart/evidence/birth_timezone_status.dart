/// Phase 3 — timezone resolution status for birth place.
library;

/// Phase 3 [resolved] = stable IANA timezoneId for the place.
/// It does NOT mean historical UTC offset has been computed (Phase 4).
enum BirthTimezoneStatus {
  missing,
  resolved,
  failed,
}

extension BirthTimezoneStatusCodec on BirthTimezoneStatus {
  String get wireName => name;

  static BirthTimezoneStatus fromWire(String? raw) {
    return switch (raw) {
      'resolved' => BirthTimezoneStatus.resolved,
      'failed' => BirthTimezoneStatus.failed,
      _ => BirthTimezoneStatus.missing,
    };
  }
}
