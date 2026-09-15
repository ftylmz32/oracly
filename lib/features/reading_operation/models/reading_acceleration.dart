/// Client outcomes for a future acceleration request.
/// Server balance and status are the only authority.
library;

enum ReadingAccelerationOutcome {
  accelerated,
  alreadyAccelerated,
  alreadyReady,

  /// The free wait was already over when the server received this request
  /// -- zero Gems charged. There was nothing left to accelerate; the caller
  /// just resumes normal waiting/processing observation.
  alreadyEligible,
  insufficientGems,
  priceChanged,
  reconcile,
}

class ReadingAccelerationView {
  const ReadingAccelerationView({
    required this.outcome,
    required this.balance,
    required this.canonicalCost,
    required this.idempotent,
    this.priceToken,
  });

  final ReadingAccelerationOutcome outcome;

  /// Present only when returned by an authoritative wallet response.
  /// Transport/protocol/reconcile failures must never invent a zero.
  final int? balance;
  final int canonicalCost;
  final bool idempotent;

  /// Fresh server-owned proof of `canonicalCost`, present on every real
  /// server response -- never invented locally. Used to arm the NEXT tap
  /// after a `priceChanged` outcome, with no extra round trip.
  final String? priceToken;
}

class ReadingGemBalance {
  const ReadingGemBalance(this.balance);

  final int balance;
}

/// Read-only preview of what accelerating THIS operation would cost --
/// never a client-invented number, and never itself a charge.
class ReadingAccelerationQuote {
  const ReadingAccelerationQuote({
    required this.canonicalCost,
    required this.balance,
    required this.priceToken,
    required this.payable,
  });

  final int canonicalCost;
  final int balance;

  /// Echoed back on the next accelerate() call to prove which price the
  /// user saw -- not authority, never the charged amount itself; the
  /// server always recomputes the real cost and only ever refuses on
  /// mismatch.
  final String priceToken;

  /// Server-authoritative: false once the free wait is already over. A UI
  /// hint only -- the real boundary is enforced by accelerate() itself
  /// regardless of what any client does with this flag.
  final bool payable;
}
