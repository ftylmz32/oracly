/// Existing chambers ORACLY may suggest. Never a new invented flow.
library;

import '../../../core/modules/oracly_feature_id.dart';

enum DiscoveryRecommendedFeature {
  dream,
  companion,
  tarot,
  starMap,
  coffee,
  palm,
  astrology,
  dailyMessage;

  OraclyFeatureId get featureId => switch (this) {
        dream => OraclyFeatureId.dream,
        companion => OraclyFeatureId.aiChat,
        tarot => OraclyFeatureId.tarot,
        starMap => OraclyFeatureId.starMap,
        coffee => OraclyFeatureId.coffee,
        palm => OraclyFeatureId.palm,
        astrology => OraclyFeatureId.astrology,
        dailyMessage => OraclyFeatureId.dailyMessage,
      };
}
