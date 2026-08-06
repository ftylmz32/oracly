/// OR-1130 — Analytics event logging abstraction.
library;

abstract class AnalyticsLogger {
  void logEvent(String name, [Map<String, Object?>? parameters]);
  void logScreen(String screenName);
  void setUserProperty(String name, String value);
}

class ConsoleAnalyticsLogger implements AnalyticsLogger {
  const ConsoleAnalyticsLogger();

  @override
  void logEvent(String name, [Map<String, Object?>? parameters]) {
    assert(name.isNotEmpty);
  }

  @override
  void logScreen(String screenName) {
    assert(screenName.isNotEmpty);
  }

  @override
  void setUserProperty(String name, String value) {
    assert(name.isNotEmpty);
  }
}
