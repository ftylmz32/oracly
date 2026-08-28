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

  static const catalog = <FeatureFlagDefinition>[
    tarot7Card,
    tarotAnimation,
    newOrVoice,
    coffeeResult,
    astrologyVisual,
    newDailyEngine,
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
