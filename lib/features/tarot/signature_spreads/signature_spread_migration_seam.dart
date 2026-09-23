/// Phase 5E — explicit read-only launch capability matrix (no wishful flags).
library;

import 'signature_spread_catalog.dart';
import 'signature_spread_definition.dart';
import 'signature_spread_shadow_status.dart';

/// Architecture-locked capability report for one Signature launch spread.
class SignatureSpreadMigrationSeam {
  const SignatureSpreadMigrationSeam({
    required this.spreadId,
    required this.runtimeSupported,
    required this.persistenceSupported,
    required this.localizationSupported,
    required this.structuralProjectionSupported,
    required this.phase3EvidenceSupported,
    required this.phase3EdgeConsumption,
    required this.phase4HistorySupported,
    required this.liveNarrativeV2Supported,
    required this.pickerOffered,
  });

  final String spreadId;
  final bool runtimeSupported;
  final bool persistenceSupported;
  final bool localizationSupported;
  final bool structuralProjectionSupported;
  final bool phase3EvidenceSupported;
  final SignaturePhase3EdgeConsumption phase3EdgeConsumption;
  final bool phase4HistorySupported;
  final bool liveNarrativeV2Supported;
  final bool pickerOffered;

  /// `null` = classical N/A · `false` = Signature edges not consumed by scorer.
  bool? get phase3SignatureEdgesConsumed =>
      phase3EdgeConsumption ==
              SignaturePhase3EdgeConsumption.classicalFrozenGlobal
          ? null
          : false;

  static SignatureSpreadMigrationSeam forDefinition(
    SignatureSpreadDefinition definition,
  ) {
    final isCrossroads = definition.spreadId == 'signature.crossroads';
    return SignatureSpreadMigrationSeam(
      spreadId: definition.spreadId,
      runtimeSupported: true,
      persistenceSupported: true,
      localizationSupported: true,
      structuralProjectionSupported: true,
      phase3EvidenceSupported: !isCrossroads,
      phase3EdgeConsumption: isCrossroads
          ? SignaturePhase3EdgeConsumption.signatureEdgesNotConsumed
          : SignaturePhase3EdgeConsumption.classicalFrozenGlobal,
      phase4HistorySupported: !isCrossroads,
      liveNarrativeV2Supported: false,
      pickerOffered: definition.offeredInLivePicker,
    );
  }

  /// Locked launch matrix in catalog order.
  static List<SignatureSpreadMigrationSeam> launchMatrix() => [
        for (final d in SignatureSpreadCatalog.launch) forDefinition(d),
      ];
}
