/// Phase 6F — flag + launch-spread gate for Narrative V2 live routing.
library;

import '../../../../core/feature_flags/feature_flag_runtime.dart';
import '../../../../core/feature_flags/product_feature_flags.dart';
import '../../domain/models/tarot_spread.dart';
import 'narrative_tarot_live_spreads.dart';

abstract final class NarrativeTarotLiveGate {
  NarrativeTarotLiveGate._();

  static bool get isFlagEnabled => FeatureFlagRuntime.isEnabled(
        ProductFeatureFlags.tarotNarrativeV2.key,
      );

  static bool isLaunchSpread(TarotSpreadType type) =>
      NarrativeTarotLiveSpreads.isLiveLaunchCandidate(type);

  /// Flag ON + single/three/five only. Seven/celtic/Crossroads → false.
  static bool shouldUseNarrative(TarotSpreadType type) =>
      isFlagEnabled && isLaunchSpread(type);
}
