/// Product analytics facade — privacy-gated, metadata only.
library;

import '../analytics/product_analytics.dart';
import '../quality/quality_feature.dart';
import '../quality/quality_signal_recorder.dart';

class AnalyticsService {
  AnalyticsService({
    ProductAnalytics? analytics,
    this.quality,
  }) : _analytics = analytics ?? ProductAnalytics();

  final ProductAnalytics _analytics;
  final QualitySignalRecorder? quality;

  void logScreenView(String name) {
    _analytics.trackScreen(name);
    _analytics.featureOpen(name);
  }

  void logAppOpen({String? destination}) => _analytics.appOpen(destination: destination);

  void logCoffeeStarted() {
    _analytics.coffeeStarted();
    quality?.started(QualityFeature.coffee);
  }

  void logCoffeeSuccess({Duration? latency}) {
    _analytics.coffeeSuccess(latency: latency);
    quality?.completed(QualityFeature.coffee);
  }

  void logCoffeeFailure({String? errorCategory}) =>
      _analytics.coffeeFailure(errorCategory: errorCategory);

  void logPalmStarted() {
    _analytics.palmStarted();
    quality?.started(QualityFeature.palm);
  }

  void logPalmSuccess({Duration? latency}) {
    _analytics.palmSuccess(latency: latency);
    quality?.completed(QualityFeature.palm);
  }

  void logPalmFailure({String? errorCategory}) =>
      _analytics.palmFailure(errorCategory: errorCategory);

  void logTarotStarted({required String spreadType}) {
    _analytics.tarotStarted(spread: spreadType);
    quality?.started(QualityFeature.tarot);
  }

  void logTarotSpreadType(String spreadType) =>
      _analytics.tarotSpreadType(spreadType);

  void logReadingCompleted({required String spreadType, String? cardName}) {
    _analytics.tarotCompleted(spread: spreadType);
    quality?.completed(QualityFeature.tarot);
  }

  void logDreamStarted() {
    _analytics.dreamStarted();
    quality?.started(QualityFeature.dream);
  }

  void logDreamCompleted({Duration? latency}) {
    _analytics.dreamCompleted(latency: latency);
    quality?.completed(QualityFeature.dream);
  }

  void logSoulmateStarted() => _analytics.soulmateStarted();
  void logSoulmateSuccess({Duration? latency}) =>
      _analytics.soulmateSuccess(latency: latency);

  void logOrMessageSent({required int length}) {
    _analytics.orMessageSent(length: length);
  }

  void logOrResponseReceived({required bool fromAi, Duration? latency}) {
    _analytics.orResponseReceived(fromAi: fromAi, latency: latency);
    quality?.completed(QualityFeature.companion);
  }

  void logAstrologyOpened() => quality?.started(QualityFeature.astrology);

  void logAstrologyCompleted() =>
      quality?.completed(QualityFeature.astrology);

  void logStarMapOpened() => quality?.started(QualityFeature.starMap);

  void logStarMapCompleted() => quality?.completed(QualityFeature.starMap);

  void logQualitySignal({
    required QualityFeature feature,
    required String signal,
    String? issue,
  }) {
    _analytics.qualitySignal(
      feature: feature.wire,
      signal: signal,
      issue: issue,
    );
  }

  void logShareOpened({required String kind}) =>
      _analytics.shareOpened(kind: kind);
  void logShareCompleted({required String kind, required String outcome}) =>
      _analytics.shareCompleted(kind: kind, outcome: outcome);

  void logPremiumViewed() => _analytics.premiumViewed();
  void logPremiumActivated(String plan) =>
      _analytics.operationResult(operation: 'premium_activate', success: true);

  void logGemPurchaseStarted({required String reason}) =>
      _analytics.gemPurchaseStarted(reason: reason);
  void logGemPurchaseSuccess({required String reason}) =>
      _analytics.gemPurchaseSuccess(reason: reason);

  void logLanguageChanged(String locale) =>
      _analytics.settingsLanguageChanged(locale: locale);

  void logOperation({
    required String operation,
    required bool success,
    Duration? latency,
    String? errorCategory,
  }) =>
      _analytics.operationResult(
        operation: operation,
        success: success,
        latency: latency,
        errorCategory: errorCategory,
      );
}
