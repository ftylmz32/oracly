/// Narrative provider attempt identity (transport only).
library;

import '../../../ai/production/openai/paid_request_idempotency.dart';

const int kMaxYildiznameProviderAttempts = 2;

abstract final class YildiznameNarrativeAttempt {
  YildiznameNarrativeAttempt._();

  static void assertValid(int attempt) {
    if (attempt != 1 && attempt != 2) {
      throw ArgumentError.value(attempt, 'attempt', 'must be 1 or 2');
    }
  }

  static String guardKey(String semanticFingerprint, int attempt) {
    assertValid(attempt);
    return 'yildizname-narrative:$semanticFingerprint:a$attempt';
  }

  static String guardFingerprint(String semanticFingerprint, int attempt) {
    assertValid(attempt);
    return '$semanticFingerprint:yildizname-attempt-$attempt';
  }

  /// HTTP Idempotency-Key: paid base + `:yv1:aN`.
  static String idempotencyKey(String semanticFingerprint, int attempt) {
    assertValid(attempt);
    final base = PaidRequestIdempotency.resolve(semanticFingerprint);
    final suffix = ':yv1:a$attempt';
    final maxBase = 128 - suffix.length;
    final trimmed =
        base.length <= maxBase ? base : base.substring(0, maxBase);
    return '$trimmed$suffix';
  }

  static int? parseAttemptSuffix(String? key) {
    if (key == null || key.isEmpty) return null;
    final match = RegExp(r':yv1:a([12])$').firstMatch(key);
    if (match == null) return null;
    return int.parse(match.group(1)!);
  }
}
