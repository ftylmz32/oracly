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
      _log(LogLevel.error, message, error, stack);

  void _log(LogLevel level, String message, [Object? data, StackTrace? stack]) {
    if (!_enabled && level == LogLevel.debug) return;
    final prefix = '[${level.name.toUpperCase()}][$tag]';
    debugPrint('$prefix $message${data != null ? ' | $data' : ''}');
    if (stack != null) debugPrint(stack.toString());
  }
}
