/// Whether the ad SDK may be prepared at all: an explicit build-time
/// rollout OR the remote `ads_v1` flag (default false). Off: the SDK is
/// never started, consent is never asked, no ad is ever requested.
library;

import '../../core/feature_flags/feature_flag_rollback.dart';
import '../../core/feature_flags/feature_flag_surface.dart';

abstract final class AdsRollout {
  AdsRollout._();

  static const buildRolloutEnabled = bool.fromEnvironment(
    'ORACLY_ADS_V1_ENABLED',
  );

  static bool get enabled =>
      buildRolloutEnabled ||
      FeatureFlagRollback.useExperimental(FeatureFlagSurface.adsV1);
}
