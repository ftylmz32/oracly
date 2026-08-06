/// OR-1130 — Firebase Analytics abstraction.
library;

import '../logging/analytics_logger.dart';

abstract class FirebaseAnalyticsService {
  Future<void> initialize();
  void logEvent(String name, [Map<String, Object?>? parameters]);
  void logScreenView(String screenName);
  void setUserId(String? userId);
}

class NoOpFirebaseAnalytics implements FirebaseAnalyticsService {
  NoOpFirebaseAnalytics({AnalyticsLogger? logger})
      : _logger = logger ?? const ConsoleAnalyticsLogger();

  final AnalyticsLogger _logger;

  @override
  Future<void> initialize() async {}

  @override
  void logEvent(String name, [Map<String, Object?>? parameters]) {
    _logger.logEvent(name, parameters);
  }

  @override
  void logScreenView(String screenName) {
    _logger.logScreen(screenName);
  }

  @override
  void setUserId(String? userId) {
    if (userId != null) _logger.setUserProperty('user_id', userId);
  }
}
