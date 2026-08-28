/// Thread-local paid op for AI requests — binds Idempotency-Key without
/// threading ids through every analyze() signature.
library;

abstract final class PaidAiOperationBinder {
  PaidAiOperationBinder._();

  static String? _activeKey;

  static String? get idempotencyKey => _activeKey;

  static Future<T> runWithKey<T>(
    String? key,
    Future<T> Function() body,
  ) async {
    final previous = _activeKey;
    if (key != null && key.isNotEmpty) _activeKey = key;
    try {
      return await body();
    } finally {
      _activeKey = previous;
    }
  }
}
