/// Canonical product analytics event names — metadata only, never user text.
library;

abstract final class ProductAnalyticsEvent {
  ProductAnalyticsEvent._();

  static const appOpen = 'app_open';
  static const featureOpen = 'feature_open';
  static const coffeeStarted = 'coffee_started';
  static const coffeeSuccess = 'coffee_success';
  static const coffeeFailure = 'coffee_failure';
  static const palmStarted = 'palm_started';
  static const palmSuccess = 'palm_success';
  static const palmFailure = 'palm_failure';
  static const tarotStarted = 'tarot_started';
  static const tarotCompleted = 'tarot_completed';
  static const tarotSpreadType = 'tarot_spread_type';
  static const dreamStarted = 'dream_started';
  static const dreamCompleted = 'dream_completed';
  static const soulmateStarted = 'soulmate_started';
  static const soulmateSuccess = 'soulmate_success';
  static const orMessageSent = 'or_message_sent';
  static const orResponseReceived = 'or_response_received';
  static const shareOpened = 'share_opened';
  static const shareCompleted = 'share_completed';
  static const premiumViewed = 'premium_viewed';
  static const gemPurchaseStarted = 'gem_purchase_started';
  static const gemPurchaseSuccess = 'gem_purchase_success';
  static const settingsLanguageChanged = 'settings_language_changed';
  static const operationResult = 'operation_result';
  static const experimentCtaShown = 'experiment_cta_shown';
  static const experimentCtaTapped = 'experiment_cta_tapped';
  static const experimentFlowCompleted = 'experiment_flow_completed';
  static const experimentFlowAbandoned = 'experiment_flow_abandoned';
  static const qualitySignal = 'quality_signal';
}
