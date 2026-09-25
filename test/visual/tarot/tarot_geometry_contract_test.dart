/// Phase 7A — geometry contracts + Crossroads firewall (visual layer).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_gate.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_spreads.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/tarot_entry/tarot_entry_spread_choice.dart';
import 'package:oracly_new/features/tarot/ritual/screens/tarot_ritual_spread_screen.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_spread_overlay.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_geometry_descriptor.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_catalog.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_crossroads.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_enums.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_migration_seam.dart';

void main() {
  test('geometry hooks are distinct; fiveDecision ≠ fiveLinear', () {
    expect(SignatureGeometryDescriptors.single.hook, SignatureGeometryHook.single);
    expect(
      SignatureGeometryDescriptors.threeLinear.hook,
      SignatureGeometryHook.threeLinear,
    );
    expect(
      SignatureGeometryDescriptors.fiveLinear.hook,
      SignatureGeometryHook.fiveLinear,
    );
    expect(
      SignatureGeometryDescriptors.fiveDecision.hook,
      SignatureGeometryHook.fiveDecision,
    );
    expect(SignatureGeometryDescriptors.fiveDecision.decisionBranching, isTrue);
    expect(SignatureGeometryDescriptors.fiveLinear.decisionBranching, isFalse);
    expect(
      SignatureGeometryDescriptors.fiveDecision.hook,
      isNot(SignatureGeometryDescriptors.fiveLinear.hook),
    );
  });

  test('Crossroads catalog uses fiveDecision, not fiveCard remapping', () {
    final cr = SignatureSpreadCatalog.bySpreadId('signature.crossroads')!;
    expect(cr.signatureGeometryHook, SignatureGeometryHook.fiveDecision);
    expect(cr.spreadId, 'signature.crossroads');
    expect(cr.spreadId, isNot('classical.fiveCard'));
    expect(kSignatureCrossroads.offeredInLivePicker, isFalse);
  });

  test('Crossroads remains absent from all public pickers + live gate', () {
    expect(
      TarotEntrySpreadChoice.offered().map((c) => c.type),
      isNot(contains(TarotSpreadType.crossroads)),
    );
    expect(
      TarotRitualSpreadScreen.offeredSpreads,
      isNot(contains(TarotSpreadType.crossroads)),
    );
    expect(
      TarotTableSpreadOverlay.options,
      isNot(contains(TarotSpreadType.crossroads)),
    );
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
  });
}
