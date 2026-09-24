/// Phase 6D — typed Narrative result failure categories.
library;

enum NarrativeTarotResultErrorKind {
  schema,
  version,
  locale,
  bounds,
  cardCoverage,
  relationshipEvidence,
  recurrenceEvidence,
  memoryEvidence,
  duplicate,
  privateIdentifier,
  quality,
  deterministicFuture,
}

final class NarrativeTarotResultException implements Exception {
  NarrativeTarotResultException(this.kind, [this.message = '']);

  final NarrativeTarotResultErrorKind kind;
  final String message;

  @override
  String toString() => 'NarrativeTarotResultException($kind: $message)';
}
