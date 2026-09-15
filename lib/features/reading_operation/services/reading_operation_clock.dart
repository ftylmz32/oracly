/// Display countdown from server timestamps plus monotonic elapsed time.
/// Device [DateTime.now] is not consulted, so changing the device clock
/// cannot move authoritative readyAt or invent a ready result.
library;

class ReadingOperationClock {
  const ReadingOperationClock();

  Duration displayRemaining({
    required DateTime readyAt,
    required DateTime serverNowAtSync,
    required Duration elapsedSinceSync,
  }) {
    final left = readyAt.difference(serverNowAtSync.add(elapsedSinceSync));
    if (left.isNegative) return Duration.zero;
    return left;
  }

  Duration offsetFromServer({
    required DateTime serverNow,
    required DateTime observedLocalNow,
  }) {
    return serverNow.difference(observedLocalNow);
  }
}
