/// Outcome of a transactional ritual settle (Phase 7D.1).
library;

enum RitualSettleOutcome {
  /// All cards settled — enter reading.
  readingReady,

  /// Card settled — actor resets for the next draw.
  continueDraw,

  /// Domain advance failed — active card preserved; retry settle only.
  failed,

  /// Another settle/retry is already in flight.
  busy,
}
