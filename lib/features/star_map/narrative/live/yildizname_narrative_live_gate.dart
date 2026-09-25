/// Feature-flag gate for Yıldızname Narrative V1 (default false).
library;

import '../../../../core/feature_flags/feature_flag_runtime.dart';
import '../../../../core/feature_flags/product_feature_flags.dart';

abstract final class YildiznameNarrativeLiveGate {
  YildiznameNarrativeLiveGate._();

  static bool get isEnabled => FeatureFlagRuntime.isEnabled(
        ProductFeatureFlags.yildiznameNarrativeV1.key,
      );
}
