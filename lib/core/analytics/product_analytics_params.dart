/// Sanitizes analytics parameters — blocks private or risky keys/values.
library;

abstract final class ProductAnalyticsParams {
  ProductAnalyticsParams._();

  static const _allowedKeys = {
    'feature',
    'spread',
    'success',
    'operation',
    'error_category',
    'latency_bucket',
    'from_ai',
    'kind',
    'outcome',
    'plan',
    'locale',
    'reason',
    'hand',
    'source',
    'length_bucket',
    'destination',
    'experiment',
    'variant',
    'signal',
    'issue',
  };

  static final _blockedKeyPattern = RegExp(
    r'message|text|content|question|body|image|token|password|email|name|'
    r'user_id|uuid|id$|prompt|response|narrative|caption|note',
    caseSensitive: false,
  );

  static Map<String, Object> sanitize(Map<String, Object?>? raw) {
    if (raw == null || raw.isEmpty) return const {};
    final out = <String, Object>{};
    for (final entry in raw.entries) {
      final key = entry.key.trim();
      if (key.isEmpty || !_allowedKeys.contains(key)) continue;
      if (_blockedKeyPattern.hasMatch(key)) continue;
      final value = entry.value;
      if (value == null) continue;
      final safe = _safeValue(value);
      if (safe != null) out[key] = safe;
    }
    return out;
  }

  static Object? _safeValue(Object value) {
    if (value is bool || value is int) return value;
    if (value is double) return value;
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 64) return null;
    if (_looksPrivate(trimmed)) return null;
    return trimmed;
  }

  static bool _looksPrivate(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('@')) return true;
    if (RegExp(r'\s{2,}').hasMatch(value) && value.length > 24) return true;
    if (RegExp(r'[.!?]').hasMatch(value) && value.length > 20) return true;
    return false;
  }

  static String latencyBucket(Duration elapsed) {
    final ms = elapsed.inMilliseconds;
    if (ms < 500) return 'lt_500ms';
    if (ms < 1500) return '500ms_1_5s';
    if (ms < 5000) return '1_5s_5s';
    if (ms < 15000) return '5s_15s';
    return 'gt_15s';
  }

  static String messageLengthBucket(int length) {
    if (length <= 0) return 'empty';
    if (length <= 24) return 'short';
    if (length <= 120) return 'medium';
    return 'long';
  }
}
