/// Phase 7F — persisted resultMode beats current Narrative V2 flag.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_gate.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_mode.dart';

void _setFlag(bool enabled) => FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.tarotNarrativeV2.key: enabled,
    });

void main() {
  tearDown(() => FeatureFlagRuntime.refreshFromRemote(const {}));

  test('saved narrativeV2 reopens V2 when live flag is OFF', () {
    _setFlag(false);
    expect(NarrativeTarotLiveGate.isFlagEnabled, isFalse);
    expect(
      ReadingResultModeResolver.of(TarotSpreadType.threeCard),
      ReadingResultMode.legacy,
    );
    expect(
      ReadingResultModeResolver.resolve(
        spread: TarotSpreadType.threeCard,
        modeOverride: ReadingResultMode.narrativeV2,
      ),
      ReadingResultMode.narrativeV2,
    );
    expect(
      ReadingResultModeResolver.parsePersisted('narrativeV2'),
      ReadingResultMode.narrativeV2,
    );
  });

  test('saved legacy reopens legacy when live flag is ON', () {
    _setFlag(true);
    expect(NarrativeTarotLiveGate.shouldUseNarrative(TarotSpreadType.threeCard),
        isTrue);
    expect(
      ReadingResultModeResolver.resolve(
        spread: TarotSpreadType.threeCard,
        modeOverride: ReadingResultMode.legacy,
      ),
      ReadingResultMode.legacy,
    );
  });

  test('missing persisted mode → conservative legacy (not live flag)', () {
    _setFlag(true);
    expect(
      ReadingResultModeResolver.parsePersisted(null),
      isNull,
    );
    // History path uses parsePersisted ?? legacy — never live of(spread).
    final override = ReadingResultModeResolver.parsePersisted(null) ??
        ReadingResultMode.legacy;
    expect(override, ReadingResultMode.legacy);
    expect(
      ReadingResultModeResolver.resolve(
        spread: TarotSpreadType.threeCard,
        modeOverride: override,
      ),
      ReadingResultMode.legacy,
    );
  });
}
