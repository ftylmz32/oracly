/// EPIC-005 — Ritual time — emotional atmosphere by day phase.
library;

/// Morning · Afternoon · Evening · Night — no redesign, only refinement.
enum OraclyRitualTime {
  morning,
  afternoon,
  evening,
  night,
}

/// Subtle environmental bias for each ritual window.
abstract final class OraclyRitualAtmosphere {
  OraclyRitualAtmosphere._();

  static OraclyRitualTime fromHour(int hour) {
    if (hour >= 5 && hour < 12) return OraclyRitualTime.morning;
    if (hour >= 12 && hour < 17) return OraclyRitualTime.afternoon;
    if (hour >= 17 && hour < 21) return OraclyRitualTime.evening;
    return OraclyRitualTime.night;
  }

  /// Warmth bias applied to gold/violet blends [-0.06 … +0.06].
  static double warmthBias(OraclyRitualTime time) => switch (time) {
        OraclyRitualTime.morning => 0.042,
        OraclyRitualTime.afternoon => 0.0,
        OraclyRitualTime.evening => 0.028,
        OraclyRitualTime.night => -0.048,
      };

  /// Overall atmospheric intensity [0.90 … 1.06].
  static double atmosphericIntensity(OraclyRitualTime time) => switch (time) {
        OraclyRitualTime.morning => 1.045,
        OraclyRitualTime.afternoon => 1.018,
        OraclyRitualTime.evening => 0.982,
        OraclyRitualTime.night => 0.938,
      };

  /// Particle density multiplier [0.86 … 1.08].
  static double particleDensity(OraclyRitualTime time) => switch (time) {
        OraclyRitualTime.morning => 1.06,
        OraclyRitualTime.afternoon => 1.0,
        OraclyRitualTime.evening => 0.96,
        OraclyRitualTime.night => 0.88,
      };

  /// Crystal reflection strength [0.94 … 1.10].
  static double crystalReflection(OraclyRitualTime time) => switch (time) {
        OraclyRitualTime.morning => 1.08,
        OraclyRitualTime.afternoon => 1.0,
        OraclyRitualTime.evening => 1.04,
        OraclyRitualTime.night => 1.02,
      };

  /// Sacred observatory veil — how open the chamber feels.
  static double observatoryVeil(OraclyRitualTime time) => switch (time) {
        OraclyRitualTime.morning => 1.03,
        OraclyRitualTime.afternoon => 1.0,
        OraclyRitualTime.evening => 0.97,
        OraclyRitualTime.night => 0.94,
      };
}
