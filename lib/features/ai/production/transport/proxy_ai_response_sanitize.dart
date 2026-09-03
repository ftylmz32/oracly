/// Sanitize proxy HTTP bodies for debug logs — never tokens or image bytes.
library;

import 'dart:convert';

abstract final class ProxyAiResponseSanitize {
  ProxyAiResponseSanitize._();

  static const _maxLen = 240;

  static String snippet(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return '<empty>';
    final lower = trimmed.toLowerCase();
    if (!lower.startsWith('{') && !lower.startsWith('[')) {
      return _clip(_redactSecrets(trimmed));
    }
    try {
      final decoded = jsonDecode(trimmed);
      return _clip(_redactMap(decoded));
    } catch (_) {
      return _clip(_redactSecrets(trimmed));
    }
  }

  static String _redactMap(Object? value) {
    if (value is Map) {
      final out = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final lower = key.toLowerCase();
        if (_isSensitiveKey(lower)) {
          out[key] = '<redacted>';
          continue;
        }
        out[key] = _redactValue(entry.value);
      }
      return out.toString();
    }
    if (value is List) {
      return '[${value.length} items]';
    }
    return _redactSecrets(value.toString());
  }

  static Object? _redactValue(Object? value) {
    if (value is Map || value is List) return _redactMap(value);
    if (value is String && value.length > 96) {
      return '<string len=${value.length}>';
    }
    return value;
  }

  static bool _isSensitiveKey(String lower) {
    return lower.contains('authorization') ||
        lower.contains('token') ||
        lower.contains('imagebase64') ||
        lower.contains('image_base64') ||
        lower.contains('b64') ||
        lower.contains('audio') ||
        lower.contains('purchase');
  }

  static String _redactSecrets(String raw) {
    return raw
        .replaceAll(
          RegExp(r'Bearer\s+\S+', caseSensitive: false),
          'Bearer <redacted>',
        )
        .replaceAll(RegExp(r'sk-[A-Za-z0-9_-]+'), '<sk-redacted>');
  }

  static String _clip(String raw) {
    if (raw.length <= _maxLen) return raw;
    return '${raw.substring(0, _maxLen)}…';
  }
}
