/// Phase 6G — Crossroads public firewall + Classical non-regression smoke.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_gate.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_spreads.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/tarot_entry/tarot_entry_spread_choice.dart';
import 'package:oracly_new/features/tarot/ritual/screens/tarot_ritual_spread_screen.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_spread_overlay.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_catalog.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_crossroads.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_migration_seam.dart';

import '../narrative_prompt/narrative_prompt_test_support.dart';

void main() {
  tearDown(() => FeatureFlagRuntime.refreshFromRemote(const {}));

  test('26 Crossroads picker remains FALSE', () {
    expect(kSignatureCrossroads.offeredInLivePicker, isFalse);
    expect(
      SignatureSpreadCatalog.bySpreadId('signature.crossroads')!
          .offeredInLivePicker,
      isFalse,
    );
    final entry =
        TarotEntrySpreadChoice.offered().map((c) => c.type).toList();
    expect(entry, isNot(contains(TarotSpreadType.crossroads)));
    expect(
      TarotRitualSpreadScreen.offeredSpreads,
      isNot(contains(TarotSpreadType.crossroads)),
    );
    expect(
      TarotTableSpreadOverlay.options,
      isNot(contains(TarotSpreadType.crossroads)),
    );
  });

  test('27 Crossroads public live admission remains disabled', () {
    FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.tarotNarrativeV2.key: true,
    });
    expect(
      NarrativeTarotLiveSpreads.isLiveLaunchCandidate(
        TarotSpreadType.crossroads,
      ),
      isFalse,
    );
    expect(
      NarrativeTarotLiveGate.shouldUseNarrative(TarotSpreadType.crossroads),
      isFalse,
    );
    final seam =
        SignatureSpreadMigrationSeam.forDefinition(kSignatureCrossroads);
    expect(seam.liveNarrativeV2Supported, isFalse);
    expect(seam.pickerOffered, isFalse);
    expect(seam.phase3EvidenceSupported, isTrue);
  });

  test('21–23 Classical single/three/five still build Classical ids', () {
    expect(
      buildFromCorpusId('single_open_fool_en').spread.spreadId,
      'classical.single',
    );
    expect(
      buildFromCorpusId('three_contrast_exemplar_en').spread.spreadId,
      'classical.threeCard',
    );
    expect(
      buildFromCorpusId('five_support_exemplar_en').spread.spreadId,
      'classical.fiveCard',
    );
  });

  test('24–25 sevenCard / celticCross not in live Narrative set', () {
    expect(
      NarrativeTarotLiveSpreads.isLiveLaunchCandidate(TarotSpreadType.sevenCard),
      isFalse,
    );
    expect(
      NarrativeTarotLiveSpreads.isLiveLaunchCandidate(
        TarotSpreadType.celticCross,
      ),
      isFalse,
    );
    FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.tarotNarrativeV2.key: true,
    });
    expect(
      NarrativeTarotLiveGate.shouldUseNarrative(TarotSpreadType.sevenCard),
      isFalse,
    );
    expect(
      NarrativeTarotLiveGate.shouldUseNarrative(TarotSpreadType.celticCross),
      isFalse,
    );
  });

  test('Classical serializer parity smoke (single)', () {
    final req = NarrativeEvidenceBuilder.build(singleTrOpenInput());
    final input = NarrativeTarotPromptSerializer.serialize(req);
    expect(input.spread.spreadId, 'classical.single');
  });
}
