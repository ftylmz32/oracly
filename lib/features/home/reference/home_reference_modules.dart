/// Live Home discovery — reference 3×2 core + Dream extension.
library;

import '../../../core/modules/oracly_feature_id.dart';
import 'home_module_visual.dart';
import 'home_reference_module_tile.dart';

abstract final class HomeReferenceModules {
  /// Coffee · Palm · Astrology · Yıldızname · SoulMate · Tarot (reference 3×2).
  static List<HomeReferenceModuleSpec> list({bool quietPremium = false}) => [
        const HomeReferenceModuleSpec(
          id: OraclyFeatureId.coffee,
          visual: HomeModuleVisual.coffee,
        ),
        const HomeReferenceModuleSpec(
          id: OraclyFeatureId.palm,
          visual: HomeModuleVisual.palm,
        ),
        const HomeReferenceModuleSpec(
          id: OraclyFeatureId.astrology,
          visual: HomeModuleVisual.astrology,
        ),
        const HomeReferenceModuleSpec(
          id: OraclyFeatureId.starMap,
          visual: HomeModuleVisual.starMap,
        ),
        HomeReferenceModuleSpec(
          id: OraclyFeatureId.soulMate,
          visual: HomeModuleVisual.soulMate,
          premiumMark: !quietPremium,
        ),
        const HomeReferenceModuleSpec(
          id: OraclyFeatureId.tarot,
          visual: HomeModuleVisual.tarot,
        ),
      ];

  /// Secondary doorway after the core six — never shrinks the 3×2.
  static const HomeReferenceModuleSpec dreamExtension = HomeReferenceModuleSpec(
    id: OraclyFeatureId.dream,
    visual: HomeModuleVisual.dream,
    isNew: true,
  );
}
