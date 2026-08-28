/// Live Home grid — seven core discovery doors (3-column wrap).
library;

import '../../../core/modules/oracly_feature_id.dart';
import 'home_module_visual.dart';
import 'home_reference_module_tile.dart';

abstract final class HomeReferenceModules {
  /// Coffee · Palm · Astrology · Yıldızname · SoulMate · Tarot · Dream.
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
        const HomeReferenceModuleSpec(
          id: OraclyFeatureId.dream,
          visual: HomeModuleVisual.dream,
          isNew: true,
        ),
      ];
}
