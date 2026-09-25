/// Phase 2 — gate result + known-gap ledger (test-only).
library;

import 'yildizname_contract_enums.dart';

class ContractGateResult {
  const ContractGateResult.pass() : kind = ContractGateResultKind.pass, reason = null;
  const ContractGateResult.fail(this.reason) : kind = ContractGateResultKind.fail;
  const ContractGateResult.knownGap(this.reason)
      : kind = ContractGateResultKind.knownGap;

  final ContractGateResultKind kind;
  final String? reason;

  bool get isPass => kind == ContractGateResultKind.pass;
  bool get isFail => kind == ContractGateResultKind.fail;
  bool get isKnownGap => kind == ContractGateResultKind.knownGap;
}

/// Current production gaps owned by later phases (not Phase 2 failures).
abstract final class YildiznameKnownGaps {
  YildiznameKnownGaps._();

  static const ownerlessBirthKey = ContractGateResult.knownGap(
    'Phase 6: birth_chart_latest still single-slot; multi-artifact owner memory pending '
    '(Phase 3 owner-safe input foundation is in place)',
  );
  static const noFrozenArtifact = ContractGateResult.knownGap(
    'Phase 6: daily leaf / reading not frozen as immutable artifact',
  );
  static const objectHashFavorite = ContractGateResult.knownGap(
    'Phase 6: favorite id uses Object.hash(title, insight)',
  );
  static const noProductionSafetyGate = ContractGateResult.knownGap(
    'Phase 5: no Yıldızname-specific production safety gate',
  );
  static const noInterpretationCraft = ContractGateResult.knownGap(
    'Phase 5: professional interpretation / groundedness / quality gate',
  );

  static const all = <ContractGateResult>[
    ownerlessBirthKey,
    noFrozenArtifact,
    objectHashFavorite,
    noProductionSafetyGate,
    noInterpretationCraft,
  ];
}
