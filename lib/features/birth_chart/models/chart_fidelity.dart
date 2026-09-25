/// How complete a natal calculation is.
library;

enum ChartCalculationFidelity {
  /// Tropical sun sign from calendar date. Not a full natal ephemeris.
  tropicalSunSign,

  /// Interval-safe signs only (unknown birth time). No Asc/MC/houses/degrees.
  reducedNatal,

  /// Exact natal from deterministic ephemeris (local astronomia).
  fullNatalEphemeris,
}
