/// Fail-closed experimental paths — exceptions always use the stable version.
library;

import 'feature_flag_runtime.dart';
import 'feature_flag_surface.dart';
import 'product_feature_flags.dart';
import 'feature_flag_definition.dart';

abstract final class FeatureFlagRollback {
  FeatureFlagRollback._();

  static FeatureFlagDefinition flag(FeatureFlagSurface surface) {
    return switch (surface) {
      FeatureFlagSurface.tarotAnimation => ProductFeatureFlags.tarotAnimation,
      FeatureFlagSurface.orVoice => ProductFeatureFlags.newOrVoice,
      FeatureFlagSurface.coffeeResult => ProductFeatureFlags.coffeeResult,
      FeatureFlagSurface.astrologyVisual => ProductFeatureFlags.astrologyVisual,
      FeatureFlagSurface.dailyMessage => ProductFeatureFlags.newDailyEngine,
    };
  }

  /// True only when the experimental path is known-good. Else stable.
  static bool useExperimental(FeatureFlagSurface surface) {
    try {
      return FeatureFlagRuntime.isEnabled(
        flag(surface).key,
        fallback: false,
      );
    } catch (_) {
      return false;
    }
  }
}
