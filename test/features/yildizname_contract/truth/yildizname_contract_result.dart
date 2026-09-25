/// Phase 2 — gate result + known-gap ledger (test-only).
library;

import 'yildizname_contract_enums.dart';

class ContractGateResult {
  const ContractGateResult.pass() : kind = ContractGateResultKind.pass, reason = null;
  const ContractGateResult.fail(this.reason) : kind = ContractGateResultKind.fail;
  const ContractGateResult.knownGap(this.reason)
      : kind = ContractGateResultKind.knownGap;
  const ContractGateResult.closed(this.reason)
      : kind = ContractGateResultKind.pass;

  final ContractGateResultKind kind;
  final String? reason;

  bool get isPass => kind == ContractGateResultKind.pass;
  bool get isFail => kind == ContractGateResultKind.fail;
  bool get isKnownGap => kind == ContractGateResultKind.knownGap;
}

/// Current production gaps owned by later phases (not Phase 2 failures).
abstract final class YildiznameKnownGaps {
  YildiznameKnownGaps._();

  /// CLOSED Phase 3+6 — owner-safe birth slot + multi-artifact Yıldızname history.
  static const ownerlessBirthKey = ContractGateResult.closed(
    'CLOSED Phase 3/6: BirthChartRecord.ownerId + yildizname_artifacts_v1 multi-artifact history',
  );

  /// CLOSED Phase 6 — immutable Yıldızname artifacts.
  static const noFrozenArtifact = ContractGateResult.closed(
    'CLOSED Phase 6: daily leaf / reading frozen as immutable artifact',
  );

  /// CLOSED Phase 6 — durable artifact id favorites (no Object.hash).
  static const objectHashFavorite = ContractGateResult.closed(
    'CLOSED Phase 6: favorite id uses durable artifact id (not Object.hash)',
  );

  /// CLOSED Phase 5 — YıldıznameNarrativeQualityValidator safety gate.
  static const noProductionSafetyGate = ContractGateResult.closed(
    'CLOSED Phase 5: Yıldızname-specific production safety gate',
  );

  /// CLOSED Phase 5 — interpretation / groundedness / quality engine.
  static const noInterpretationCraft = ContractGateResult.closed(
    'CLOSED Phase 5: professional interpretation / groundedness / quality gate',
  );

  /// Phase 7 — final result architecture / scope disclosure chrome.
  static const presentationChrome = ContractGateResult.knownGap(
    'Phase 7: final result architecture / scope-fidelity disclosure UI',
  );

  /// Open gaps only — Phase 7 presentation remains.
  static const all = <ContractGateResult>[
    presentationChrome,
  ];
}
