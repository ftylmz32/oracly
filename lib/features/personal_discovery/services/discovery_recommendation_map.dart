/// Observable theme / source → existing chamber. Never a score.
library;

import '../models/discovery_recommended_feature.dart';
import '../models/discovery_theme.dart';

abstract final class DiscoveryRecommendationMap {
  DiscoveryRecommendationMap._();

  static DiscoveryRecommendedFeature? forTheme(String raw) {
    final theme = DiscoveryTheme.resolve(raw);
    return switch (theme) {
      DiscoveryTheme.decision ||
      DiscoveryTheme.indecision ||
      DiscoveryTheme.uncertainty ||
      DiscoveryTheme.communication ||
      DiscoveryTheme.courage ||
      DiscoveryTheme.redirection =>
        DiscoveryRecommendedFeature.companion,
      DiscoveryTheme.career ||
      DiscoveryTheme.change ||
      DiscoveryTheme.newBeginning =>
        DiscoveryRecommendedFeature.tarot,
      DiscoveryTheme.relationship ||
      DiscoveryTheme.love ||
      DiscoveryTheme.family =>
        DiscoveryRecommendedFeature.starMap,
      _ => null,
    };
  }

  static DiscoveryRecommendedFeature? forSource(String source) {
    return switch (source) {
      'dream' => DiscoveryRecommendedFeature.dream,
      'tarot' => DiscoveryRecommendedFeature.tarot,
      'coffee' => DiscoveryRecommendedFeature.coffee,
      'palm' => DiscoveryRecommendedFeature.palm,
      'reflection' => DiscoveryRecommendedFeature.companion,
      'astrology' => DiscoveryRecommendedFeature.astrology,
      'star' || 'starMap' || 'star_map' => DiscoveryRecommendedFeature.starMap,
      'daily' || 'dailyMessage' => DiscoveryRecommendedFeature.dailyMessage,
      _ => null,
    };
  }
}
