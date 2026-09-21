/// Async-context paid operation binding — isolates Idempotency-Key per
/// logical request, including overlapping Futures on the same Dart isolate.
library;

import 'dart:async';

abstract final class PaidAiOperationBinder {
  PaidAiOperationBinder._();

  static const Object _zoneKey = #oraclyPaidAiOperationIdempotencyKey;

  static String? get idempotencyKey {
    final value = Zone.current[_zoneKey];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Runs [body] with [key] visible only to this async Zone. Concurrent
  /// operations therefore cannot overwrite one another, and nested calls
  /// automatically restore the parent binding when they return.
  static Future<T> runWithKey<T>(
    String? key,
    Future<T> Function() body,
  ) {
    final normalized = key?.trim();
    if (normalized == null || normalized.isEmpty) return body();
    return runZoned(
      body,
      zoneValues: <Object?, Object?>{_zoneKey: normalized},
    );
  }
}
