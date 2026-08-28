/// Privacy-safe product analytics — anonymous usage, never user content.
library;

import 'package:flutter/foundation.dart';

import '../logging/analytics_logger.dart';
import '../monitoring/firebase_analytics.dart';
import 'product_analytics_event.dart';
import 'product_analytics_params.dart';

typedef AnalyticsEnabled = bool Function();

class ProductAnalytics {
  ProductAnalytics({
    FirebaseAnalyticsService? sink,
    AnalyticsLogger? logger,
    AnalyticsEnabled? isEnabled,
  })  : _sink = sink,
        _logger = logger ?? const ConsoleAnalyticsLogger(),
        _isEnabled = isEnabled ?? (() => true);

  final FirebaseAnalyticsService? _sink;
  final AnalyticsLogger _logger;
  final AnalyticsEnabled _isEnabled;

  void track(String name, [Map<String, Object?>? params]) {
    if (!_isEnabled()) return;
    final safe = ProductAnalyticsParams.sanitize(params);
    _sink?.logEvent(name, safe.isEmpty ? null : safe);
    if (kDebugMode) {
      _logger.logEvent(name, safe.isEmpty ? null : safe);
    }
  }

  void trackScreen(String screen) {
    if (!_isEnabled() || screen.trim().isEmpty) return;
    _sink?.logScreenView(screen);
    if (kDebugMode) _logger.logScreen(screen);
  }

  void appOpen({String? destination}) => track(
        ProductAnalyticsEvent.appOpen,
        {if (destination != null) 'destination': destination},
      );

  void featureOpen(String feature) =>
      track(ProductAnalyticsEvent.featureOpen, {'feature': feature});

  void coffeeStarted() => track(ProductAnalyticsEvent.coffeeStarted);
  void coffeeSuccess({Duration? latency}) => track(
        ProductAnalyticsEvent.coffeeSuccess,
        {if (latency != null) 'latency_bucket': ProductAnalyticsParams.latencyBucket(latency)},
      );
  void coffeeFailure({String? errorCategory}) => track(
        ProductAnalyticsEvent.coffeeFailure,
        {if (errorCategory != null) 'error_category': errorCategory},
      );

  void palmStarted() => track(ProductAnalyticsEvent.palmStarted);
  void palmSuccess({Duration? latency}) => track(
        ProductAnalyticsEvent.palmSuccess,
        {if (latency != null) 'latency_bucket': ProductAnalyticsParams.latencyBucket(latency)},
      );
  void palmFailure({String? errorCategory}) => track(
        ProductAnalyticsEvent.palmFailure,
        {if (errorCategory != null) 'error_category': errorCategory},
      );

  void tarotStarted({required String spread}) => track(
        ProductAnalyticsEvent.tarotStarted,
        {'spread': spread},
      );
  void tarotSpreadType(String spread) =>
      track(ProductAnalyticsEvent.tarotSpreadType, {'spread': spread});
  void tarotCompleted({required String spread}) => track(
        ProductAnalyticsEvent.tarotCompleted,
        {'spread': spread},
      );

  void dreamStarted() => track(ProductAnalyticsEvent.dreamStarted);
  void dreamCompleted({Duration? latency}) => track(
        ProductAnalyticsEvent.dreamCompleted,
        {if (latency != null) 'latency_bucket': ProductAnalyticsParams.latencyBucket(latency)},
      );

  void soulmateStarted() => track(ProductAnalyticsEvent.soulmateStarted);
  void soulmateSuccess({Duration? latency}) => track(
        ProductAnalyticsEvent.soulmateSuccess,
        {if (latency != null) 'latency_bucket': ProductAnalyticsParams.latencyBucket(latency)},
      );

  void orMessageSent({required int length}) => track(
        ProductAnalyticsEvent.orMessageSent,
        {
          'length_bucket':
              ProductAnalyticsParams.messageLengthBucket(length),
        },
      );
  void orResponseReceived({required bool fromAi, Duration? latency}) => track(
        ProductAnalyticsEvent.orResponseReceived,
        {
          'from_ai': fromAi,
          if (latency != null) 'latency_bucket': ProductAnalyticsParams.latencyBucket(latency),
        },
      );

  void shareOpened({required String kind}) =>
      track(ProductAnalyticsEvent.shareOpened, {'kind': kind});
  void shareCompleted({required String kind, required String outcome}) => track(
        ProductAnalyticsEvent.shareCompleted,
        {'kind': kind, 'outcome': outcome},
      );

  void premiumViewed() => track(ProductAnalyticsEvent.premiumViewed);
  void gemPurchaseStarted({required String reason}) =>
      track(ProductAnalyticsEvent.gemPurchaseStarted, {'reason': reason});
  void gemPurchaseSuccess({required String reason}) =>
      track(ProductAnalyticsEvent.gemPurchaseSuccess, {'reason': reason});

  void settingsLanguageChanged({required String locale}) =>
      track(ProductAnalyticsEvent.settingsLanguageChanged, {'locale': locale});

  void qualitySignal({
    required String feature,
    required String signal,
    String? issue,
  }) =>
      track(ProductAnalyticsEvent.qualitySignal, {
        'feature': feature,
        'signal': signal,
        if (issue != null) 'issue': issue,
      });

  void operationResult({
    required String operation,
    required bool success,
    Duration? latency,
    String? errorCategory,
  }) =>
      track(ProductAnalyticsEvent.operationResult, {
        'operation': operation,
        'success': success,
        if (latency != null) 'latency_bucket': ProductAnalyticsParams.latencyBucket(latency),
        if (errorCategory != null) 'error_category': errorCategory,
      });
}
