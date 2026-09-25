/// Phase 2 — allowed fact matrix (test-only).
library;

import 'yildizname_contract_enums.dart';

class MatrixCell {
  const MatrixCell({
    required this.allowed,
    this.requiredFidelity,
    this.allowedCertainty = const {},
  });

  final bool allowed;
  final ContractFidelity? requiredFidelity;
  final Set<ContractFactCertainty> allowedCertainty;
}

abstract final class YildiznameFactMatrix {
  YildiznameFactMatrix._();

  static const _u = {
    ContractFactCertainty.unavailable,
    ContractFactCertainty.unsupported,
  };
  static const _iu = {
    ContractFactCertainty.intervalStable,
    ContractFactCertainty.ambiguous,
    ContractFactCertainty.unavailable,
    ContractFactCertainty.unsupported,
  };
  static const _ex = {ContractFactCertainty.exact};

  static MatrixCell cell(ContractFactType t, ContractEvidenceState e) =>
      _rows[t]![e]!;

  static final _rows =
      <ContractFactType, Map<ContractEvidenceState, MatrixCell>>{
    ContractFactType.sunIdentity: _sun(),
    ContractFactType.sunLongitude: _long(),
    for (final p in [
      ContractFactType.moon,
      ContractFactType.mercury,
      ContractFactType.venus,
      ContractFactType.mars,
      ContractFactType.jupiter,
      ContractFactType.saturn,
      ContractFactType.uranus,
      ContractFactType.neptune,
      ContractFactType.pluto,
    ])
      p: _planet(),
    ContractFactType.ascendant: _asc(),
    ContractFactType.mc: _asc(),
    ContractFactType.houses: _asc(),
    ContractFactType.aspects: _asp(),
    ContractFactType.elementBalance: _sym(),
    ContractFactType.modalityBalance: _sym(),
    ContractFactType.natalThemes: _sym(),
    ContractFactType.archiveNarrative: _sym(),
    ContractFactType.dailySymbolicLeaf: {
      for (final e in ContractEvidenceState.values)
        e: MatrixCell(
          allowed: e != ContractEvidenceState.e0,
          allowedCertainty: {..._ex, ..._u},
        ),
    },
    ContractFactType.transits: {
      for (final e in ContractEvidenceState.values)
        e: const MatrixCell(allowed: false),
    },
  };

  static Map<ContractEvidenceState, MatrixCell> _sun() => {
        ContractEvidenceState.e0: const MatrixCell(allowed: false),
        for (final e in [
          ContractEvidenceState.e1,
          ContractEvidenceState.e2,
          ContractEvidenceState.e3,
        ])
          e: MatrixCell(
            allowed: true,
            requiredFidelity: ContractFidelity.tropicalSunSign,
            allowedCertainty: _ex,
          ),
        ContractEvidenceState.e4: MatrixCell(
          allowed: true,
          requiredFidelity: ContractFidelity.fullNatalEphemeris,
          allowedCertainty: {..._ex, ..._u},
        ),
      };

  static Map<ContractEvidenceState, MatrixCell> _long() => {
        ContractEvidenceState.e0: const MatrixCell(allowed: false),
        ContractEvidenceState.e1: const MatrixCell(allowed: false),
        ContractEvidenceState.e2: MatrixCell(allowed: false, allowedCertainty: _u),
        ContractEvidenceState.e3: MatrixCell(allowed: false, allowedCertainty: _u),
        ContractEvidenceState.e4:
            MatrixCell(allowed: true, allowedCertainty: {..._ex, ..._u}),
      };

  static Map<ContractEvidenceState, MatrixCell> _planet() => {
        ContractEvidenceState.e0: const MatrixCell(allowed: false),
        ContractEvidenceState.e1: const MatrixCell(allowed: false),
        ContractEvidenceState.e2:
            MatrixCell(allowed: true, allowedCertainty: _iu),
        ContractEvidenceState.e3:
            MatrixCell(allowed: true, allowedCertainty: _iu),
        ContractEvidenceState.e4:
            MatrixCell(allowed: true, allowedCertainty: {..._ex, ..._u}),
      };

  static Map<ContractEvidenceState, MatrixCell> _asc() => {
        ContractEvidenceState.e0: const MatrixCell(allowed: false),
        ContractEvidenceState.e1: const MatrixCell(allowed: false),
        ContractEvidenceState.e2: MatrixCell(
          allowed: false,
          allowedCertainty: {ContractFactCertainty.unavailable},
        ),
        ContractEvidenceState.e3: MatrixCell(
          allowed: false,
          allowedCertainty: {ContractFactCertainty.unavailable},
        ),
        ContractEvidenceState.e4:
            MatrixCell(allowed: true, allowedCertainty: {..._ex, ..._u}),
      };

  static Map<ContractEvidenceState, MatrixCell> _asp() => _planet();

  static Map<ContractEvidenceState, MatrixCell> _sym() => {
        ContractEvidenceState.e0: const MatrixCell(allowed: false),
        ContractEvidenceState.e1: MatrixCell(
          allowed: true,
          requiredFidelity: ContractFidelity.tropicalSunSign,
          allowedCertainty: _ex,
        ),
        ContractEvidenceState.e2: MatrixCell(
          allowed: true,
          requiredFidelity: ContractFidelity.reducedNatal,
          allowedCertainty: _ex,
        ),
        ContractEvidenceState.e3: MatrixCell(
          allowed: true,
          requiredFidelity: ContractFidelity.reducedNatal,
          allowedCertainty: _ex,
        ),
        ContractEvidenceState.e4:
            MatrixCell(allowed: true, allowedCertainty: {..._ex, ..._u}),
      };
}
