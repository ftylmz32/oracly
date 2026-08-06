/// OR-1130 — Performance trace abstraction.
library;

abstract class PerformanceTrace {
  void start();
  void stop();
  void putMetric(String name, int value);
}

abstract class PerformanceLogger {
  PerformanceTrace startTrace(String name);
  void recordMetric(String name, Duration duration);
}

class ConsolePerformanceLogger implements PerformanceLogger {
  @override
  PerformanceTrace startTrace(String name) => _ConsoleTrace(name);

  @override
  void recordMetric(String name, Duration duration) {
    assert(name.isNotEmpty);
  }
}

class _ConsoleTrace implements PerformanceTrace {
  _ConsoleTrace(this.name);
  final String name;
  DateTime? _started;

  @override
  void start() => _started = DateTime.now();

  @override
  void stop() {
    if (_started == null) return;
    final elapsed = DateTime.now().difference(_started!);
    assert(elapsed.inMilliseconds >= 0);
  }

  @override
  void putMetric(String name, int value) {
    assert(name.isNotEmpty);
  }
}
