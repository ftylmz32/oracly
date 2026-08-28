import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_debug_overrides.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_evaluator.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';

void main() {
  setUp(() {
    FeatureFlagDebugOverrides.clear();
    FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
  });

  group('FeatureFlagEvaluator', () {
    test('uses safe defaults when remote values are missing', () {
      final resolved = FeatureFlagEvaluator.evaluate(const {});
      expect(resolved[ProductFeatureFlags.tarot7Card.key], isTrue);
      expect(resolved[ProductFeatureFlags.newOrVoice.key], isTrue);
      expect(resolved[ProductFeatureFlags.newDailyEngine.key], isTrue);
    });

    test('ignores invalid remote values and keeps defaults', () {
      FeatureFlagRuntime.refreshFromRemote({
        ProductFeatureFlags.tarot7Card.key: false,
        'unknown_flag': true,
      });
      expect(
        FeatureFlagRuntime.isEnabled(ProductFeatureFlags.tarot7Card.key),
        isFalse,
      );
      expect(FeatureFlagRuntime.isEnabled('unknown_flag'), isFalse);
    });

    test('falls back to defaults on evaluation failure', () {
      FeatureFlagRuntime.refreshFromRemote(const {});
      expect(
        FeatureFlagRuntime.isEnabled(ProductFeatureFlags.newDailyEngine.key),
        isTrue,
      );
    });
  });

  group('FeatureFlagDebugOverrides', () {
    test('applies overrides only in debug mode', () {
      FeatureFlagDebugOverrides.set(ProductFeatureFlags.tarot7Card.key, false);
      if (kDebugMode) {
        expect(
          FeatureFlagEvaluator.evaluate(const {})[
              ProductFeatureFlags.tarot7Card.key],
          isFalse,
        );
      } else {
        expect(
          FeatureFlagEvaluator.evaluate(const {})[
              ProductFeatureFlags.tarot7Card.key],
          isTrue,
        );
      }
    });

    test('release safety — overrides are inert outside debug', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      if (!kDebugMode) {
        FeatureFlagDebugOverrides.set(ProductFeatureFlags.newOrVoice.key, false);
        expect(FeatureFlagDebugOverrides.read(ProductFeatureFlags.newOrVoice.key),
            isNull);
      }
    });
  });
}
