/// Anonymous experiment funnel metrics — never logs copy or user content.
library;

import '../analytics/product_analytics.dart';
import '../analytics/product_analytics_event.dart';

abstract final class ExperimentAnalytics {
  ExperimentAnalytics._();

  static void ctaShown(
    ProductAnalytics analytics, {
    required String experimentId,
    required String variant,
    required String feature,
  }) =>
      _track(
        analytics,
        ProductAnalyticsEvent.experimentCtaShown,
        experimentId: experimentId,
        variant: variant,
        feature: feature,
      );

  static void ctaTapped(
    ProductAnalytics analytics, {
    required String experimentId,
    required String variant,
    required String feature,
  }) =>
      _track(
        analytics,
        ProductAnalyticsEvent.experimentCtaTapped,
        experimentId: experimentId,
        variant: variant,
        feature: feature,
      );

  static void flowCompleted(
    ProductAnalytics analytics, {
    required String experimentId,
    required String variant,
    required String feature,
  }) =>
      _track(
        analytics,
        ProductAnalyticsEvent.experimentFlowCompleted,
        experimentId: experimentId,
        variant: variant,
        feature: feature,
      );

  static void flowAbandoned(
    ProductAnalytics analytics, {
    required String experimentId,
    required String variant,
    required String feature,
  }) =>
      _track(
        analytics,
        ProductAnalyticsEvent.experimentFlowAbandoned,
        experimentId: experimentId,
        variant: variant,
        feature: feature,
      );

  static void _track(
    ProductAnalytics analytics,
    String event, {
    required String experimentId,
    required String variant,
    required String feature,
  }) {
    analytics.track(event, {
      'experiment': experimentId,
      'variant': variant,
      'feature': feature,
    });
  }
}
