/// Observational next-chamber choice. Recency first, never random.
library;

import '../models/cross_discovery_insight.dart';
import '../models/discovery_recommend_kind.dart';
import '../models/discovery_recommendation.dart';
import '../models/discovery_recommended_feature.dart';
import '../models/discovery_source_activity.dart';
import '../models/personal_discovery_profile.dart';
import 'discovery_recommendation_availability.dart';
import 'discovery_recommendation_day.dart';
import 'discovery_recommendation_map.dart';

abstract final class DiscoveryRecommendationEngine {
  DiscoveryRecommendationEngine._();

  static const recentDays = 7;
  static const monthDays = 30;

  static DiscoveryRecommendation decide(
    PersonalDiscoveryProfile profile, {
    DateTime? now,
    Set<DiscoveryRecommendedFeature>? available,
  }) {
    final clock = now ?? DateTime.now();
    final offered = DiscoveryRecommendationAvailability.offered(
      override: available,
    );
    final done = DiscoveryRecommendationDay.completed(profile, clock);
    final fallback = offered.contains(DiscoveryRecommendedFeature.dailyMessage)
        ? DiscoveryRecommendation.empty
        : DiscoveryRecommendation(
            feature: offered.first,
            kind: DiscoveryRecommendKind.empty,
          );

    final week = _window(profile, clock, recentDays);
    final month = _window(profile, clock, monthDays);
    final slice = week.hasEvidence ? week : (month.hasEvidence ? month : null);
    if (slice == null) return fallback;

    return _fromThemes(
          slice.insights,
          slice.activities,
          offered,
          done,
        ) ??
        _fromSources(slice.activities, offered, done) ??
        fallback;
  }

  static DiscoveryRecommendation? _fromThemes(
    List<CrossDiscoveryInsight> insights,
    List<DiscoverySourceActivity> activities,
    Set<DiscoveryRecommendedFeature> offered,
    Set<DiscoveryRecommendedFeature> done,
  ) {
    final latest = _mostRecentFeature(activities);
    final ranked = [
      for (final insight in insights)
        if (DiscoveryRecommendationMap.forTheme(insight.theme) case final feature?
            when offered.contains(feature) &&
                DiscoveryRecommendationDay.unused(feature, done))
          (insight, feature),
    ]..sort((a, b) {
        final recency = b.$1.lastObserved.compareTo(a.$1.lastObserved);
        if (recency != 0) return recency;
        final count = b.$1.discoveryCount.compareTo(a.$1.discoveryCount);
        if (count != 0) return count;
        return a.$1.theme.compareTo(b.$1.theme);
      });
    if (ranked.isEmpty) return null;
    final pick = _preferDifferent(ranked, latest, (row) => row.$2);
    return DiscoveryRecommendation(
      feature: pick.$2,
      kind: DiscoveryRecommendKind.theme,
      theme: pick.$1.theme,
      recurring: pick.$1.isRecurring || pick.$1.discoveryCount >= 2,
    );
  }

  static DiscoveryRecommendation? _fromSources(
    List<DiscoverySourceActivity> activities,
    Set<DiscoveryRecommendedFeature> offered,
    Set<DiscoveryRecommendedFeature> done,
  ) {
    final latest = _mostRecentFeature(activities);
    final ranked = [
      for (final item in activities)
        if (DiscoveryRecommendationMap.forSource(item.source) case final feature?
            when offered.contains(feature) &&
                DiscoveryRecommendationDay.unused(feature, done))
          (item, feature),
    ]..sort((a, b) {
        final recency = b.$1.lastAt.compareTo(a.$1.lastAt);
        if (recency != 0) return recency;
        final count = b.$1.recentCount.compareTo(a.$1.recentCount);
        if (count != 0) return count;
        return a.$1.source.compareTo(b.$1.source);
      });
    if (ranked.isEmpty) return null;
    final pick = _preferDifferent(ranked, latest, (row) => row.$2);
    return DiscoveryRecommendation(
      feature: pick.$2,
      kind: DiscoveryRecommendKind.source,
      source: pick.$1.source,
      evidenceCount: pick.$1.recentCount,
    );
  }

  /// Prefer a different chamber than the one just used — never invent a pick.
  static T _preferDifferent<T>(
    List<T> ranked,
    DiscoveryRecommendedFeature? latest,
    DiscoveryRecommendedFeature Function(T row) featureOf,
  ) {
    if (latest == null || ranked.length < 2) return ranked.first;
    for (final row in ranked) {
      if (featureOf(row) != latest) return row;
    }
    return ranked.first;
  }

  static DiscoveryRecommendedFeature? _mostRecentFeature(
    List<DiscoverySourceActivity> activities,
  ) {
    if (activities.isEmpty) return null;
    DiscoverySourceActivity? newest;
    for (final item in activities) {
      if (newest == null || item.lastAt.isAfter(newest.lastAt)) {
        newest = item;
      }
    }
    return DiscoveryRecommendationMap.forSource(newest!.source);
  }

  static ({
    List<DiscoverySourceActivity> activities,
    List<CrossDiscoveryInsight> insights,
    bool hasEvidence,
  }) _window(
    PersonalDiscoveryProfile profile,
    DateTime now,
    int days,
  ) {
    final activities = [
      for (final item in profile.sourceActivity)
        if (DiscoveryRecommendationDay.within(item.lastAt, now, days)) item,
    ];
    final insights = [
      for (final item in profile.crossInsights)
        if (DiscoveryRecommendationDay.within(item.lastObserved, now, days) &&
            DiscoveryRecommendationMap.forTheme(item.theme) != null)
          item,
    ];
    return (
      activities: activities,
      insights: insights,
      hasEvidence: activities.isNotEmpty,
    );
  }
}
