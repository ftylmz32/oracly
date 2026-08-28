/// Strips secrets and user-like content from crash payloads.
library;

import '../../features/ai/production/ai_failure.dart';
import '../network/network_exception.dart';

abstract final class CrashReportSanitizer {
  CrashReportSanitizer._();

  static const _maxStackChars = 8192;

  static final _secret = RegExp(
    r'(sk-[A-Za-z0-9_-]{8,}|api[_-]?key\s*[:=]\s*\S+|bearer\s+[a-z0-9._-]+)',
    caseSensitive: false,
  );

  static String safeErrorCode(Object error) {
    if (error is AiFailure) return error.kind.name;
    if (error is NetworkException) return error.kind.name;
    if (error is AiFailureKind) return error.name;
    if (error is NetworkErrorKind) return error.name;
    return error.runtimeType.toString();
  }

  static String safeStack(StackTrace stack) {
    var text = scrub(stack.toString());
    if (text.length > _maxStackChars) {
      text = '${text.substring(0, _maxStackChars)}…';
    }
    return text;
  }

  static String scrub(String? raw) {
    if (raw == null) return '';
    var out = raw.replaceAll(_secret, '[redacted]');
    out = out.replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'), '');
    return out.trim();
  }

  static String? networkClass(Object? error) {
    if (error is NetworkException) {
      return switch (error.kind) {
        NetworkErrorKind.noConnection => 'offline',
        NetworkErrorKind.timeout => 'timeout',
        NetworkErrorKind.server => 'server',
        _ => 'degraded',
      };
    }
    return null;
  }
}
