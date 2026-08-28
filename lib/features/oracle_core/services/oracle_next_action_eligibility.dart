/// Eligibility rules for Oracle Core NextAction MVP.
library;

import '../../personal_discovery/models/cross_discovery_insight.dart';
import '../../personal_discovery/models/discovery_recommended_feature.dart';
import '../../personal_discovery/models/discovery_source_activity.dart';
import '../../personal_discovery/models/discovery_theme_strength.dart';
import '../../personal_discovery/services/discovery_recommendation_day.dart';
import '../../personal_discovery/services/discovery_recommendation_map.dart';

abstract final class OracleNextActionEligibility {
  OracleNextActionEligibility._();

  static const minOccurrences = 2;
  static const minSourceFeatures = 2;
  static const recentDays = 30;

  static bool insightQualifies(
    CrossDiscoveryInsight insight,
    DateTime now,
  ) {
    if (insight.sourceCount < minSourceFeatures) return false;
    if (insight.discoveryCount < minOccurrences) return false;
    if (insight.confidence == DiscoveryThemeStrength.observed) return false;
    if (!DiscoveryRecommendationDay.within(
      insight.lastObserved,
      now,
      recentDays,
    )) {
      return false;
    }
    return true;
  }

  static bool featureAllowed(
    DiscoveryRecommendedFeature feature,
    List<DiscoverySourceActivity> activity,
    DateTime now,
  ) {
    final done = <DiscoveryRecommendedFeature>{
      for (final item in activity)
        if (DiscoveryRecommendationDay.sameDay(item.lastAt, now))
          ?DiscoveryRecommendationMap.forSource(item.source),
    };
    return DiscoveryRecommendationDay.unused(feature, done);
  }
}
