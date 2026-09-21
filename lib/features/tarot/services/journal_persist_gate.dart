/// Coalesces concurrent Tarot journal persist attempts into one job.
library;

/// Shared gate used by ReadingScreen auto-save and manual Save.
///
/// When two callers enter before [completed] flips, the second awaits the
/// first job. Note offer runs at most once after durable success.
class JournalPersistGate {
  Future<void>? _inFlight;
  bool _pendingOfferNote = false;
  Future<void> Function()? _onOfferNote;
  bool completed = false;

  Future<void> run({
    required Future<void> Function() body,
    bool offerNote = false,
    Future<void> Function()? onOfferNote,
  }) async {
    if (completed) {
      if (offerNote) await onOfferNote?.call();
      return;
    }
    if (offerNote) {
      _pendingOfferNote = true;
      if (onOfferNote != null) _onOfferNote = onOfferNote;
    }
    final inFlight = _inFlight;
    if (inFlight != null) {
      await inFlight;
      return;
    }
    final job = _execute(body: body);
    _inFlight = job;
    try {
      await job;
    } finally {
      if (identical(_inFlight, job)) {
        _inFlight = null;
      }
    }
  }

  Future<void> _execute({required Future<void> Function() body}) async {
    if (completed) {
      await _flushNoteOffer();
      return;
    }
    // [body] must set [completed] = true only after durable success.
    await body();
    await _flushNoteOffer();
  }

  Future<void> _flushNoteOffer() async {
    if (!_pendingOfferNote || !completed) {
      _pendingOfferNote = false;
      _onOfferNote = null;
      return;
    }
    final offer = _onOfferNote;
    _pendingOfferNote = false;
    _onOfferNote = null;
    await offer?.call();
  }
}
