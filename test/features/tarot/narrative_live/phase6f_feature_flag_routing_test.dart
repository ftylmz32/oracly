/// Phase 6F — `tarot_narrative_v2` flag → live routing gate.
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_gate.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_spreads.dart';

const _launch = <TarotSpreadType>[
  TarotSpreadType.single,
  TarotSpreadType.threeCard,
  TarotSpreadType.fiveCard,
];

const _excluded = <TarotSpreadType>[
  TarotSpreadType.sevenCard,
  TarotSpreadType.celticCross,
  TarotSpreadType.crossroads,
];

void _setFlag(bool enabled) => FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.tarotNarrativeV2.key: enabled,
    });

void main() {
  tearDown(() => FeatureFlagRuntime.refreshFromRemote(const {}));

  group('flag definition', () {
    test('key and default are the launch contract', () {
      expect(ProductFeatureFlags.tarotNarrativeV2.key, 'tarot_narrative_v2');
      expect(ProductFeatureFlags.tarotNarrativeV2.defaultValue, isTrue);
      expect(
        ProductFeatureFlags.definitionFor('tarot_narrative_v2'),
        same(ProductFeatureFlags.tarotNarrativeV2),
      );
      expect(ProductFeatureFlags.defaults()['tarot_narrative_v2'], isTrue);
    });

    test('unknown remote payload leaves the default ON', () {
      FeatureFlagRuntime.refreshFromRemote(const {'not_a_flag': false});
      expect(
        FeatureFlagRuntime.isEnabled('tarot_narrative_v2'),
        isTrue,
      );
      expect(NarrativeTarotLiveGate.isFlagEnabled, isTrue);
    });
  });

  group('flag ON', () {
    setUp(() => _setFlag(true));

    test('single / threeCard / fiveCard route to Narrative', () {
      expect(FeatureFlagRuntime.isEnabled('tarot_narrative_v2'), isTrue);
      for (final type in _launch) {
        expect(
          NarrativeTarotLiveGate.shouldUseNarrative(type),
          isTrue,
          reason: '$type must route to Narrative V2 when the flag is on',
        );
      }
    });

    test('sevenCard / celticCross / crossroads stay legacy', () {
      for (final type in _excluded) {
        expect(
          NarrativeTarotLiveGate.shouldUseNarrative(type),
          isFalse,
          reason: '$type is outside the Narrative launch set',
        );
      }
    });
  });

  group('flag OFF', () {
    setUp(() => _setFlag(false));

    test('every launch spread falls back to legacy', () {
      expect(FeatureFlagRuntime.isEnabled('tarot_narrative_v2'), isFalse);
      expect(NarrativeTarotLiveGate.isFlagEnabled, isFalse);
      for (final type in _launch) {
        expect(NarrativeTarotLiveGate.shouldUseNarrative(type), isFalse);
      }
    });

    test('launch-spread membership is flag independent', () {
      for (final type in _launch) {
        expect(NarrativeTarotLiveGate.isLaunchSpread(type), isTrue);
      }
      for (final type in _excluded) {
        expect(NarrativeTarotLiveGate.isLaunchSpread(type), isFalse);
      }
    });
  });

  group('launch spread catalog', () {
    test('exactly single / threeCard / fiveCard', () {
      expect(NarrativeTarotLiveSpreads.spreads, _launch.toSet());
    });

    test('Crossroads is never a launch candidate', () {
      expect(
        NarrativeTarotLiveSpreads.spreads,
        isNot(contains(TarotSpreadType.crossroads)),
      );
      expect(
        NarrativeTarotLiveSpreads.isLiveLaunchCandidate(
          TarotSpreadType.crossroads,
        ),
        isFalse,
      );
      expect(
        () => NarrativeTarotLiveSpreads.narrativeSpreadId(
          TarotSpreadType.crossroads,
        ),
        throwsArgumentError,
      );
    });

    test('narrative spread ids match the Classical machine ids', () {
      expect(
        NarrativeTarotLiveSpreads.narrativeSpreadId(TarotSpreadType.single),
        'classical.single',
      );
      expect(
        NarrativeTarotLiveSpreads.narrativeSpreadId(TarotSpreadType.threeCard),
        'classical.threeCard',
      );
      expect(
        NarrativeTarotLiveSpreads.narrativeSpreadId(TarotSpreadType.fiveCard),
        'classical.fiveCard',
      );
    });
  });
}
