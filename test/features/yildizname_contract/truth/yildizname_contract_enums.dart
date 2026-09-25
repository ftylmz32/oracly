/// Phase 2 — contract enums (test-only).
library;

enum ContractEvidenceState { e0, e1, e2, e3, e4 }

enum ContractFactCertainty {
  exact,
  intervalStable,
  ambiguous,
  unavailable,
  unsupported,
}

enum ContractFidelity {
  tropicalSunSign,
  reducedNatal,
  fullNatalEphemeris,
}

enum ContractFactType {
  sunIdentity,
  sunLongitude,
  moon,
  mercury,
  venus,
  mars,
  jupiter,
  saturn,
  uranus,
  neptune,
  pluto,
  ascendant,
  mc,
  houses,
  aspects,
  elementBalance,
  modalityBalance,
  natalThemes,
  archiveNarrative,
  dailySymbolicLeaf,
  transits,
}

enum ContractScope { legacy, reduced, full }

enum ContractGateResultKind { pass, fail, knownGap }
