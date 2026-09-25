/// Phase 9 — spread picker / Crossroads bypass firewall.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_gate.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_spread_overlay.dart';

import 'phase9_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => FeatureFlagRuntime.refreshFromRemote(const {}));

  test('public overlay excludes seven/celtic/crossroads', () {
    final ids = TarotTableSpreadOverlay.options.toSet();
    expect(ids.contains(TarotSpreadType.sevenCard), isFalse);
    expect(ids.contains(TarotSpreadType.celticCross), isFalse);
    expect(ids.contains(TarotSpreadType.crossroads), isFalse);
    expect(ids.contains(TarotSpreadType.single), isTrue);
    expect(ids.contains(TarotSpreadType.threeCard), isTrue);
    expect(ids.contains(TarotSpreadType.fiveCard), isTrue);
  });

  test('programmatic beginSession(crossroads) is internal-only', () async {
    // NOTE: beginSession accepts any TarotSpreadType — picker never offers it.
    final (_, repo, ctrl) = await bootRepo();
    final session = await ctrl.beginSession(
      spread: TarotSpreadType.crossroads,
      deckId: 'classic',
    );
    expect(session.spread, TarotSpreadType.crossroads);
    expect(session.requiredCardCount, 5);
    expect(TarotTableSpreadOverlay.options, isNot(contains(session.spread)));
    expect(repo.saveCount, greaterThan(0));
    ctrl.dispose();
  });

  test('NarrativeTarotLiveGate false for crossroads even with flag ON', () {
    FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.tarotNarrativeV2.key: true,
    });
    expect(NarrativeTarotLiveGate.isFlagEnabled, isTrue);
    expect(
      NarrativeTarotLiveGate.shouldUseNarrative(TarotSpreadType.crossroads),
      isFalse,
    );
    expect(
      NarrativeTarotLiveGate.isLaunchSpread(TarotSpreadType.crossroads),
      isFalse,
    );
  });
}
