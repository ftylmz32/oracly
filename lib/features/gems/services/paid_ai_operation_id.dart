/// Stable paid-operation IDs — safe for Idempotency-Key and gem ledgers.
library;

import 'dart:math';

abstract final class PaidAiOperationId {
  PaidAiOperationId._();

  static final Random _random = Random.secure();

  /// Format: `or-{feature}-{time}-{entropy}` (header-safe, ≤128 chars).
  static String create(String feature) {
    final safe = feature.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final entropy = List.generate(16, (_) => _random.nextInt(256))
        .map((n) => n.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'or-$safe-$entropy';
  }

  /// Tarot sessions already have a stable id — normalize for headers.
  static String fromExisting(String feature, String existing) {
    final trimmed = existing.trim();
    if (trimmed.startsWith('or-') && _valid(trimmed)) return trimmed;
    final safe = trimmed
        .replaceAll(RegExp(r'[^A-Za-z0-9._:-]'), '')
        .takeChars(80);
    final tag = feature.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return 'or-$tag-$safe';
  }

  static bool _valid(String key) =>
      key.length <= 128 && RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(key);
}

extension on String {
  String takeChars(int n) => length <= n ? this : substring(0, n);
}
