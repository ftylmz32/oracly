/// How complete a natal calculation is.
library;

enum ChartCalculationFidelity {
  /// Tropical sun sign from calendar date. Not a full natal ephemeris.
  tropicalSunSign,
  /// Full natal from a real ephemeris (Swiss Ephemeris or equivalent).
  fullNatalEphemeris,
}
