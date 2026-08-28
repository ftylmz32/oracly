/// OR-1130 — Structured application logger.
library;

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  Logger(this.tag);

  final String tag;

  bool get _enabled =>
      !AppConfig.isInitialized || AppConfig.instance.enableLogging;

  void debug(String message, [Object? data]) =>
      _log(LogLevel.debug, message, data);

  void info(String message, [Object? data]) =>
      _log(LogLevel.info, message, data);

  void warning(String message, [Object? data]) =>
      _log(LogLevel.warning, message, data);

  void error(String message, [Object? error, StackTrace? stack]) =>
      _log(LogLevel.error, message, error);

  void _log(LogLevel level, String message, [Object? data]) {
    if (!kDebugMode) return;
    if (!_enabled && level == LogLevel.debug) return;
    final body = data == null
        ? _scrub(message)
        : '${_scrub(message)} ${_scrub(data.toString())}';
    debugPrint('[${level.name.toUpperCase()}][$tag] $body');
  }

  /// Never echo provider keys / bearer tokens even in debug.
  @visibleForTesting
  static String scrub(String message) {
    var out = message;
    out = out.replaceAllMapped(
      RegExp(r'(sk-[A-Za-z0-9_\-]{8,})'),
      (_) => 'sk-[redacted]',
    );
    out = out.replaceAllMapped(
      RegExp(r'(Bearer\s+)[A-Za-z0-9._\-]+', caseSensitive: false),
      (m) => '${m[1]}[redacted]',
    );
    out = out.replaceAllMapped(
      RegExp(
        r'((?:api[_-]?key|openai_api_key|authorization)\s*[:=]\s*)\S+',
        caseSensitive: false,
      ),
      (m) => '${m[1]}[redacted]',
    );
    return out;
  }

  static String _scrub(String message) => scrub(message);
}
