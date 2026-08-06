/// OR-1130 — Exponential backoff retry for transient failures.
library;

import 'network_exception.dart';
import 'api_interceptor.dart';

class RetryInterceptor implements ApiInterceptor {
  RetryInterceptor({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  final int maxAttempts;
  final Duration baseDelay;

  int _attempt = 0;

  bool shouldRetry(NetworkException error) {
    return error.kind == NetworkErrorKind.timeout ||
        error.kind == NetworkErrorKind.noConnection ||
        (error.statusCode != null && error.statusCode! >= 500);
  }

  Duration delayForAttempt(int attempt) {
    final multiplier = 1 << attempt.clamp(0, 4);
    return Duration(milliseconds: baseDelay.inMilliseconds * multiplier);
  }

  void reset() => _attempt = 0;

  int get attempt => _attempt;

  void incrementAttempt() => _attempt++;

  @override
  Future<Map<String, String>> onRequest(Map<String, String> headers) async =>
      headers;

  @override
  Future<void> onResponse(int statusCode, Map<String, String> headers) async {
    if (statusCode >= 200 && statusCode < 300) reset();
  }

  @override
  Future<void> onError(Object error) async {}
}
