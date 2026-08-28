/// Emergency rollback — experimental off or failed → stable path.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_debug_overrides.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_evaluator.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_rollback.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_surface.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/features/daily_message/services/daily_return_composer.dart';
import 'package:oracly_new/features/tarot/presentation/animations/tarot_transition.dart';
import 'package:flutter/material.dart';

void main() {
  setUp(() {
    FeatureFlagDebugOverrides.clear();
    FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
  });

  test('each experimental surface has a catalog flag', () {
    for (final surface in FeatureFlagSurface.values) {
      expect(FeatureFlagRollback.flag(surface).key, isNotEmpty);
    }
  });

  test('remote false rolls back every surface to stable', () {
    FeatureFlagRuntime.refreshFromRemote({
      for (final surface in FeatureFlagSurface.values)
        FeatureFlagRollback.flag(surface).key: false,
    });
    for (final surface in FeatureFlagSurface.values) {
      expect(FeatureFlagRollback.useExperimental(surface), isFalse);
    }
  });

  test('unknown flag never opens an experimental path', () {
    expect(FeatureFlagRuntime.isEnabled('unknown_flag'), isFalse);
  });

  test('tarot animation rollback keeps a real route', () {
    FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.tarotAnimation.key: false,
    });
    final route = tarotRitualRoute(page: const SizedBox());
    expect(route, isA<PageRoute<void>>());
    expect(
      FeatureFlagRollback.useExperimental(FeatureFlagSurface.tarotAnimation),
      isFalse,
    );
  });

  test('daily message rollback still returns text and a CTA action', () {
    FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.newDailyEngine.key: false,
    });
    final composed = DailyReturnComposer.compose(
      day: DateTime(2026, 8, 20),
    );
    expect(composed.text.trim(), isNotEmpty);
    expect(composed.theme, isNull);
    expect(composed.action, isNotNull);
  });

  test('or voice rollback uses the stable device path', () {
    FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.newOrVoice.key: false,
    });
    expect(
      FeatureFlagRollback.useExperimental(FeatureFlagSurface.orVoice),
      isFalse,
    );
  });

  test('evaluator keeps defaults when remote omits a flag', () {
    final resolved = FeatureFlagEvaluator.evaluate(const {});
    expect(resolved[ProductFeatureFlags.tarotAnimation.key], isTrue);
    expect(resolved[ProductFeatureFlags.coffeeResult.key], isTrue);
    expect(resolved[ProductFeatureFlags.astrologyVisual.key], isTrue);
  });
}
