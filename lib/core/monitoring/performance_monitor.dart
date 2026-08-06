/// OR-1130 — Firebase Performance abstraction.
library;

import '../logging/performance_logger.dart';

abstract class PerformanceMonitoringService {
  Future<void> initialize();
  PerformanceTrace newTrace(String name);
  void recordHttpMetric(String url, int responseCode, Duration duration);
}

class NoOpPerformanceMonitoring implements PerformanceMonitoringService {
  NoOpPerformanceMonitoring({PerformanceLogger? logger})
      : _logger = logger ?? ConsolePerformanceLogger();

  final PerformanceLogger _logger;

  @override
  Future<void> initialize() async {}

  @override
  PerformanceTrace newTrace(String name) {
    final trace = _logger.startTrace(name);
    trace.start();
    return trace;
  }

  @override
  void recordHttpMetric(String url, int responseCode, Duration duration) {
    _logger.recordMetric('http_$responseCode', duration);
  }
}
