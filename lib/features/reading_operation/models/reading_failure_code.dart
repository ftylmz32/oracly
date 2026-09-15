/// Allow-listed durable-operation failure classification (public wire).
library;

/// Matches backend `FAILURE_CODES`. Unknown/missing → [unknown].
enum ReadingFailureCode {
  unavailable,
  invalid,
  cancelled,
  entitlementDenied,
  unknown,
}

ReadingFailureCode readingFailureCodeFromWire(Object? value) {
  return switch (value) {
    'unavailable' => ReadingFailureCode.unavailable,
    'invalid' => ReadingFailureCode.invalid,
    'cancelled' => ReadingFailureCode.cancelled,
    'entitlement_denied' => ReadingFailureCode.entitlementDenied,
    _ => ReadingFailureCode.unknown,
  };
}

extension ReadingFailureCodeX on ReadingFailureCode {
  bool get isEntitlementDenial => this == ReadingFailureCode.entitlementDenied;
}
