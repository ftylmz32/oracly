/// Product flags for real implemented variants — no speculative toggles.
library;

import 'feature_flag_definition.dart';
import 'feature_flag_type.dart';

abstract final class ProductFeatureFlags {
  ProductFeatureFlags._();

  static const tarot7Card = FeatureFlagDefinition(
    key: 'tarot_7_card',
    type: FeatureFlagType.boolean,
    defaultValue: true,
  );

  /// Phase 6F — Classical single/three/five Narrative V2 live path.
  /// Remote `false` restores legacy AI Tarot without migration.
  static const tarotNarrativeV2 = FeatureFlagDefinition(
    key: 'tarot_narrative_v2',
    type: FeatureFlagType.boolean,
    defaultValue: true,
  );

  static const tarotAnimation = FeatureFlagDefinition(
    key: 'tarot_animation',
    type: FeatureFlagType.boolean,
    defaultValue: true,
  );

  static const newOrVoice = FeatureFlagDefinition(
    key: 'new_or_voice',
    type: FeatureFlagType.boolean,
    defaultValue: true,
    minAppVersion: '1.0.0',
  );

  static const coffeeResult = FeatureFlagDefinition(
    key: 'coffee_result',
    type: FeatureFlagType.boolean,
    defaultValue: true,
  );

  static const astrologyVisual = FeatureFlagDefinition(
    key: 'astrology_visual',
    type: FeatureFlagType.boolean,
    defaultValue: true,
  );

  static const newDailyEngine = FeatureFlagDefinition(
    key: 'new_daily_engine',
    type: FeatureFlagType.boolean,
    defaultValue: true,
  );

  /// Shipping Narrative V1. Remote `false` restores the local archive.
  static const yildiznameNarrativeV1 = FeatureFlagDefinition(
    key: 'yildizname_narrative_v1',
    type: FeatureFlagType.boolean,
    defaultValue: true,
  );

  /// Coffee V3 four-view client capture (Turkish only). Gates starting a
  /// NEW four-photo capture only — an existing V3 draft stays reachable and
  /// an already-created V3 operation always recovers. Dark by default.
  static const coffeeV3FourView = FeatureFlagDefinition(
    key: 'coffee_v3_four_view',
    type: FeatureFlagType.boolean,
    defaultValue: false,
  );

  static const catalog = <FeatureFlagDefinition>[
    tarot7Card,
    tarotNarrativeV2,
    tarotAnimation,
    newOrVoice,
    coffeeResult,
    astrologyVisual,
    newDailyEngine,
    yildiznameNarrativeV1,
    coffeeV3FourView,
  ];

  static Map<String, bool> defaults() => {
    for (final flag in catalog) flag.key: flag.defaultValue,
  };

  static FeatureFlagDefinition? definitionFor(String key) {
    for (final flag in catalog) {
      if (flag.key == key) return flag;
    }
    return null;
  }
}
