/// Phase 4 — astronomical bodies and angles (not presentation PlanetId).
library;

enum NatalBody {
  sun,
  moon,
  mercury,
  venus,
  mars,
  jupiter,
  saturn,
  uranus,
  neptune,
  pluto,
}

enum NatalAngleKind { ascendant, midheaven }

/// Bodies counted for element/modality balance (no Asc/MC).
const natalBalanceBodies = <NatalBody>[
  NatalBody.sun,
  NatalBody.moon,
  NatalBody.mercury,
  NatalBody.venus,
  NatalBody.mars,
  NatalBody.jupiter,
  NatalBody.saturn,
  NatalBody.uranus,
  NatalBody.neptune,
  NatalBody.pluto,
];

/// Bodies participating in Phase 4 baseline aspects.
const natalAspectBodies = natalBalanceBodies;
