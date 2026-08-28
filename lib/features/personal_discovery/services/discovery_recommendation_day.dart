/// Calendar-day helpers for one daily suggestion. Never a lottery.
library;

import '../models/discovery_recommended_feature.dart';
import '../models/personal_discovery_profile.dart';
import 'discovery_recommendation_map.dart';

abstract final class DiscoveryRecommendationDay {
  DiscoveryRecommendationDay._();

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool within(DateTime at, DateTime now, int days) =>
      !at.isAfter(now) && now.difference(at).inDays <= days;

  /// Chambers already used today — skip so we do not nag a completed action.
  static Set<DiscoveryRecommendedFeature> completed(
    PersonalDiscoveryProfile profile,
    DateTime now,
  ) {
    return {
      for (final item in profile.sourceActivity)
        if (sameDay(item.lastAt, now))
          ?DiscoveryRecommendationMap.forSource(item.source),
    };
  }

  static bool unused(
    DiscoveryRecommendedFeature feature,
    Set<DiscoveryRecommendedFeature> done,
  ) =>
      !done.contains(feature);
}
