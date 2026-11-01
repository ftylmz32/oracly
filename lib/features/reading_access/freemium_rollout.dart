/// Whether the Freemium V1 client experience is shown: an explicit
/// build-time rollout OR the remote `freemium_v1` flag (default false).
/// Off: every entry, error and Premium surface is exactly as before. The
/// server keeps its own independent gate, so this never grants a reading.
library;

import '../../core/feature_flags/feature_flag_rollback.dart';
import '../../core/feature_flags/feature_flag_surface.dart';

abstract final class FreemiumRollout {
  FreemiumRollout._();

  static const buildRolloutEnabled = bool.fromEnvironment(
    'ORACLY_FREEMIUM_V1_ENABLED',
  );

  static bool get enabled =>
      buildRolloutEnabled ||
      FeatureFlagRollback.useExperimental(FeatureFlagSurface.freemiumV1);
}
