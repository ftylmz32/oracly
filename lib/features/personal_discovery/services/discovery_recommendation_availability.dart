/// Chambers that currently have a real screen. Reserved modules stay out.
library;

import '../../../core/modules/oracly_feature_availability.dart';
import '../../../core/modules/oracly_feature_registry.dart';
import '../models/discovery_recommended_feature.dart';

abstract final class DiscoveryRecommendationAvailability {
  DiscoveryRecommendationAvailability._();

  static Set<DiscoveryRecommendedFeature> offered({
    Set<DiscoveryRecommendedFeature>? override,
  }) {
    if (override != null) return Set.unmodifiable(override);
    return {
      for (final feature in DiscoveryRecommendedFeature.values)
        if (_navigable(feature)) feature,
    };
  }

  static bool _navigable(DiscoveryRecommendedFeature feature) {
    final module = OraclyFeatureRegistry.byId(feature.featureId);
    if (module == null) return false;
    return module.availability != OraclyFeatureAvailability.reserved;
  }
}
