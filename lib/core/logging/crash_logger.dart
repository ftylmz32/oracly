/// OR-1130 — Crash reporting abstraction.
library;

import '../telemetry/crash_report.dart';
import 'logger.dart';

abstract class CrashLogger {
  void recordError(Object error, StackTrace stack, {bool fatal = false});
  void recordReport(CrashReport report, {bool fatal = false});
  void log(String message);
  void setUserId(String? userId);
}

class ConsoleCrashLogger implements CrashLogger {
  ConsoleCrashLogger({Logger? logger}) : _logger = logger ?? Logger('Crash');

  final Logger _logger;

  @override
  void recordError(Object error, StackTrace stack, {bool fatal = false}) {
    _logger.error('Crash recorded (fatal=$fatal)', error, stack);
  }

  @override
  void recordReport(CrashReport report, {bool fatal = false}) {
    _logger.warning(
      'Crash report fatal=$fatal meta=${report.toMetadata()}',
    );
  }

  @override
  void log(String message) => _logger.warning(message);

  @override
  void setUserId(String? userId) {
    _logger.info('Crash user context: ${userId == null ? 'none' : 'set'}');
  }
}
