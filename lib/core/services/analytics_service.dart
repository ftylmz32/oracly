/// OR-1100 — Analytics stub — ready for Firebase/Mixpanel.
library;

class AnalyticsService {
  const AnalyticsService();

  void logScreenView(String name) {
    assert(name.isNotEmpty);
  }

  void logEvent(String name, [Map<String, Object?>? params]) {
    assert(name.isNotEmpty);
  }

  void logReadingCompleted({required String spreadType, required String cardName}) {
    logEvent('reading_completed', {
      'spread': spreadType,
      'card': cardName,
    });
  }

  void logPremiumActivated(String plan) {
    logEvent('premium_activated', {'plan': plan});
  }
}
