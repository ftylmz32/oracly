/// OR-1130 — Crashlytics abstraction.
library;

import '../logging/crash_logger.dart';

abstract class CrashlyticsService {
  Future<void> initialize();
  void recordError(Object error, StackTrace stack, {bool fatal = false});
  void log(String message);
  void setUserIdentifier(String? userId);
}

class NoOpCrashlyticsService implements CrashlyticsService {
  NoOpCrashlyticsService({CrashLogger? logger})
      : _logger = logger ?? ConsoleCrashLogger();

  final CrashLogger _logger;

  @override
  Future<void> initialize() async {}

  @override
  void recordError(Object error, StackTrace stack, {bool fatal = false}) {
    _logger.recordError(error, stack, fatal: fatal);
  }

  @override
  void log(String message) => _logger.log(message);

  @override
  void setUserIdentifier(String? userId) => _logger.setUserId(userId);
}
