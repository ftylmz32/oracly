/// Phase 4 — birth instant resolution kinds and result.
library;

enum BirthInstantKind {
  exact,
  ambiguous,
  nonexistent,
  unavailable,
  unsupportedDate,
}

class BirthInstantResolution {
  const BirthInstantResolution._({
    required this.kind,
    this.utc,
    this.candidates = const [],
  });

  const BirthInstantResolution.exact(DateTime utc)
      : this._(kind: BirthInstantKind.exact, utc: utc);

  const BirthInstantResolution.ambiguous(List<DateTime> candidates)
      : this._(kind: BirthInstantKind.ambiguous, candidates: candidates);

  const BirthInstantResolution.nonexistent()
      : this._(kind: BirthInstantKind.nonexistent);

  const BirthInstantResolution.unavailable()
      : this._(kind: BirthInstantKind.unavailable);

  const BirthInstantResolution.unsupportedDate()
      : this._(kind: BirthInstantKind.unsupportedDate);

  final BirthInstantKind kind;
  final DateTime? utc;
  final List<DateTime> candidates;

  bool get isExact => kind == BirthInstantKind.exact && utc != null;
}
