/// Phase 6F.1 — Narrative provider attempt identity (transport only).
library;

import '../../../ai/production/openai/paid_request_idempotency.dart';

/// Max real Narrative provider generations per top-level load.
const int kMaxNarrativeProviderAttempts = 2;

abstract final class NarrativeTarotAttempt {
  NarrativeTarotAttempt._();

  static void assertValid(int attempt) {
    if (attempt != 1 && attempt != 2) {
      throw ArgumentError.value(attempt, 'attempt', 'must be 1 or 2');
    }
  }

  /// Client AiRequestGuard key — attempt-isolated.
  static String guardKey(String semanticFingerprint, int attempt) {
    assertValid(attempt);
    return 'tarot-narrative:$semanticFingerprint:a$attempt';
  }

  /// Client AiRequestGuard fingerprint — attempt-isolated.
  static String guardFingerprint(String semanticFingerprint, int attempt) {
    assertValid(attempt);
    return '$semanticFingerprint:narrative-attempt-$attempt';
  }

  /// HTTP Idempotency-Key: paid base + `:nv2:aN` (≤128, header-safe).
  static String idempotencyKey(String semanticFingerprint, int attempt) {
    assertValid(attempt);
    final base = PaidRequestIdempotency.resolve(semanticFingerprint);
    final suffix = ':nv2:a$attempt';
    final maxBase = 128 - suffix.length;
    final trimmed =
        base.length <= maxBase ? base : base.substring(0, maxBase);
    return '$trimmed$suffix';
  }

  /// True when [key] carries a Narrative attempt suffix (a1|a2).
  static int? parseAttemptSuffix(String? key) {
    if (key == null || key.isEmpty) return null;
    final match = RegExp(r':nv2:a([12])$').firstMatch(key);
    if (match == null) return null;
    return int.parse(match.group(1)!);
  }
}
