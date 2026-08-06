/// OR-1180 — Interpretation failure taxonomy.
library;

enum InterpretationFailureType {
  retry,
  timeout,
  offline,
  emptyResponse,
  invalidResponse,
}

class InterpretationException implements Exception {
  const InterpretationException({
    required this.type,
    required this.message,
    this.cause,
    this.retryable = true,
  });

  final InterpretationFailureType type;
  final String message;
  final Object? cause;
  final bool retryable;

  @override
  String toString() => 'InterpretationException($type): $message';
}

class InterpretationRetryPolicy {
  const InterpretationRetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 400),
    this.backoffMultiplier = 2.0,
  });

  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;

  Duration delayForAttempt(int attempt) {
    final factor = backoffMultiplier * (attempt - 1);
    return Duration(
      milliseconds: (initialDelay.inMilliseconds * (1 + factor)).round(),
    );
  }
}
