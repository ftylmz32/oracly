/// Map failures to calm copy — never HTTP, providers, stacks, or operations.
library;

import '../copy/resilience_copy.dart';
import '../network/network_exception.dart';

abstract final class AiErrorSanitizer {
  AiErrorSanitizer._();

  static final _secret = RegExp(
    r'(sk-[A-Za-z0-9_-]+|api[_-]?key\s*[:=]\s*\S+)',
    caseSensitive: false,
  );

  static final _technical = RegExp(
    r'(https?://|\bhttp\s*[:=]?\s*\d{3}\b|\bstatus\b|\bexception\b|'
    r'\bstack(\s*trace)?\b|\.dart\b|\bopenai\b|\banthropic\b|\bfirebase\b|'
    r'\bgpt-|\bsocketexception\b|\bdioexception\b|\bxmlhttprequest\b|'
    r'\bprovider_error\b|\binternal_error\b|\binternal operation\b|'
    r'\bproxy\b|\btimeout exception\b)',
    caseSensitive: false,
  );

  static String publicMessage({
    Object? error,
    String? fallback,
  }) {
    final resolved = fallback ?? ResilienceCopy.aiUnavailable;
    if (error == null) return resolved;
    if (error is NetworkException) return _fromNetwork(error);
    return guard(error.toString(), fallback: resolved);
  }

  static String guard(String? candidate, {String? fallback}) {
    final resolved = fallback ?? ResilienceCopy.aiUnavailable;
    if (candidate == null) return resolved;
    final trimmed = candidate.trim();
    if (trimmed.isEmpty) return resolved;
    final mapped = _fromCode(trimmed);
    if (mapped != null) return mapped;
    if (_leaks(trimmed)) return resolved;
    return trimmed;
  }

  static String _fromNetwork(NetworkException error) {
    return switch (error.kind) {
      NetworkErrorKind.timeout => ResilienceCopy.slowResponse,
      NetworkErrorKind.noConnection => ResilienceCopy.offline,
      NetworkErrorKind.unauthorized ||
      NetworkErrorKind.forbidden =>
        ResilienceCopy.aiUnauthorized,
      NetworkErrorKind.server => ResilienceCopy.aiUnavailable,
      NetworkErrorKind.notFound => ResilienceCopy.genericLoadFailed,
      NetworkErrorKind.parse ||
      NetworkErrorKind.cancelled ||
      NetworkErrorKind.unknown =>
        ResilienceCopy.temporaryFailure,
    };
  }

  static String? _fromCode(String raw) {
    if (raw.contains(' ')) return null;
    return switch (raw.trim().toLowerCase()) {
      // Reachability of OR/proxy — not a device-offline wall.
      'network' || 'network_error' => ResilienceCopy.aiUnavailable,
      'timeout' => ResilienceCopy.slowResponse,
      'rate_limit' || 'rate_limited' => ResilienceCopy.aiRateLimited,
      'no_configuration' => ResilienceCopy.aiConfigMissing,
      'unauthorized' || 'forbidden' => ResilienceCopy.aiUnauthorized,
      'invalid_response' => ResilienceCopy.aiEmptyResponse,
      'internal_error' || 'provider_error' => ResilienceCopy.aiUnavailable,
      'no_connection' || 'offline' => ResilienceCopy.offline,
      _ => null,
    };
  }

  static bool _leaks(String raw) {
    if (_secret.hasMatch(raw)) return true;
    if (_technical.hasMatch(raw)) return true;
    if (RegExp(r'Instance of\s').hasMatch(raw)) return true;
    if (RegExp(r'^(Exception|Error|StateError|AssertionError)\b',
            caseSensitive: false)
        .hasMatch(raw)) {
      return true;
    }
    if (raw.contains('#0 ') || raw.contains('package:')) return true;
    if (RegExp(r'\b[45]\d{2}\b').hasMatch(raw) &&
        raw.toLowerCase().contains('error')) {
      return true;
    }
    return false;
  }
}
