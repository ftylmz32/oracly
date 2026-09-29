/// Maps a discovery recommendation onto the day's free next step.
library;

import '../../personal_discovery/models/discovery_recommended_feature.dart';
import '../models/daily_return_action.dart';

DailyReturnAction dailyReturnActionFor(
  DiscoveryRecommendedFeature feature,
  DailyReturnAction fallback,
) {
  return switch (feature) {
    DiscoveryRecommendedFeature.companion => DailyReturnAction.talkToOr,
    DiscoveryRecommendedFeature.dream => DailyReturnAction.tellDream,
    DiscoveryRecommendedFeature.tarot => DailyReturnAction.askTarot,
    DiscoveryRecommendedFeature.starMap => DailyReturnAction.exploreStarMap,
    DiscoveryRecommendedFeature.coffee => DailyReturnAction.readCoffee,
    DiscoveryRecommendedFeature.palm => DailyReturnAction.readPalm,
    DiscoveryRecommendedFeature.astrology => DailyReturnAction.readAstrology,
    DiscoveryRecommendedFeature.dailyMessage => fallback,
  };
}
