/// Diagnostics counts for Phase 4C snapshot load (no ids/text).
library;

class TarotHistoryNormalizeDiagnostics {
  const TarotHistoryNormalizeDiagnostics({
    this.skippedOwnerMismatch = 0,
    this.skippedMalformed = 0,
    this.skippedMissingSource = 0,
  });

  final int skippedOwnerMismatch;
  final int skippedMalformed;
  final int skippedMissingSource;

  TarotHistoryNormalizeDiagnostics operator +(
    TarotHistoryNormalizeDiagnostics o,
  ) {
    return TarotHistoryNormalizeDiagnostics(
      skippedOwnerMismatch: skippedOwnerMismatch + o.skippedOwnerMismatch,
      skippedMalformed: skippedMalformed + o.skippedMalformed,
      skippedMissingSource: skippedMissingSource + o.skippedMissingSource,
    );
  }
}
