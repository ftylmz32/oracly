/// EPIC-005 — Seasonal ambient palettes — whisper-level shifts.
library;

/// Northern-hemisphere seasonal rhythm (matches primary audience locale).
enum OraclySeason {
  spring,
  summer,
  autumn,
  winter,
}

abstract final class OraclySeasonalPalette {
  OraclySeasonalPalette._();

  static OraclySeason fromMonth(int month) => switch (month) {
        3 || 4 || 5 => OraclySeason.spring,
        6 || 7 || 8 => OraclySeason.summer,
        9 || 10 || 11 => OraclySeason.autumn,
        _ => OraclySeason.winter,
      };

  /// Warmth bias for particle and nebula blends.
  static double warmthBias(OraclySeason season) => switch (season) {
        OraclySeason.spring => 0.018,
        OraclySeason.summer => 0.032,
        OraclySeason.autumn => 0.024,
        OraclySeason.winter => -0.026,
      };

  /// Atmospheric density — winter feels quieter, summer slightly fuller.
  static double atmosphericIntensity(OraclySeason season) => switch (season) {
        OraclySeason.spring => 1.012,
        OraclySeason.summer => 1.028,
        OraclySeason.autumn => 0.998,
        OraclySeason.winter => 0.962,
      };

  /// Particle count feel — not literal count, opacity multiplier.
  static double particleDensity(OraclySeason season) => switch (season) {
        OraclySeason.spring => 1.04,
        OraclySeason.summer => 1.06,
        OraclySeason.autumn => 0.98,
        OraclySeason.winter => 0.90,
      };

  /// Seasonal crystal tone — autumn gold, winter violet calm.
  static double crystalReflection(OraclySeason season) => switch (season) {
        OraclySeason.spring => 1.02,
        OraclySeason.summer => 1.0,
        OraclySeason.autumn => 1.05,
        OraclySeason.winter => 0.96,
      };
}
