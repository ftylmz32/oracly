/// EPIC-005 — The Living Universe — environmental state from natural time.
library;

import 'oracly_living_event.dart';
import 'oracly_moon_phase.dart';
import 'oracly_ritual_time.dart';
import 'oracly_season.dart';

/// Complete environmental snapshot — layout-neutral, feeling-rich.
class OraclyUniverseState {
  const OraclyUniverseState({
    required this.moment,
    required this.ritualTime,
    required this.season,
    required this.moonPhase,
    required this.moonIllumination,
    this.livingEvent,
  });

  final DateTime moment;
  final OraclyRitualTime ritualTime;
  final OraclySeason season;
  final OraclyMoonPhase moonPhase;
  final double moonIllumination;
  final OraclyLivingEvent? livingEvent;

  /// Compute from wall clock — cheap, no controllers.
  factory OraclyUniverseState.current([DateTime? now]) {
    final moment = now ?? DateTime.now();
    return OraclyUniverseState(
      moment: moment,
      ritualTime: OraclyRitualAtmosphere.fromHour(moment.hour),
      season: OraclySeasonalPalette.fromMonth(moment.month),
      moonPhase: OraclyMoonLighting.phase(moment),
      moonIllumination: OraclyMoonLighting.illumination(moment),
      livingEvent: OraclyLivingEvent.resolve(moment),
    );
  }

  OraclyUniverseModulation get modulation => OraclyUniverseModulation(this);
}

/// Applies universe state to existing layer opacities — never changes layout.
class OraclyUniverseModulation {
  const OraclyUniverseModulation(this.state);

  final OraclyUniverseState state;

  double _blend3(double ritual, double moon, double season) =>
      (ritual * 0.52 + moon * 0.28 + season * 0.20).clamp(0.86, 1.12);

  /// Multiplier for veil and chamber glow opacity.
  double veilOpacity(double base) {
    final ritual = OraclyRitualAtmosphere.observatoryVeil(state.ritualTime);
    final moon = OraclyMoonLighting.observatoryBreath(
      state.moonIllumination,
      (state.moment.millisecondsSinceEpoch % 12000) / 12000.0,
    );
    final season = OraclySeasonalPalette.atmosphericIntensity(state.season);
    return (base * _blend3(ritual, moon, season)).clamp(0.0, 1.0);
  }

  /// Multiplier for particle layers.
  double particleOpacity(double base) {
    final ritual = OraclyRitualAtmosphere.particleDensity(state.ritualTime);
    final season = OraclySeasonalPalette.particleDensity(state.season);
    final moon = 0.94 + state.moonIllumination * 0.10;
    return (base * _blend3(ritual, moon, season)).clamp(0.0, 1.0);
  }

  /// Multiplier for crystal breath and shimmer layers.
  double crystalOpacity(double base) {
    final ritual = OraclyRitualAtmosphere.crystalReflection(state.ritualTime);
    final moon = OraclyMoonLighting.crystalReflection(state.moonIllumination);
    final season = OraclySeasonalPalette.crystalReflection(state.season);
    return (base * _blend3(ritual, moon, season)).clamp(0.0, 1.0);
  }

  /// Multiplier for nebula and traveling light intensity.
  double atmosphericOpacity(double base) {
    final ritual =
        OraclyRitualAtmosphere.atmosphericIntensity(state.ritualTime);
    final moon =
        OraclyMoonLighting.atmosphericIntensity(state.moonIllumination);
    final season = OraclySeasonalPalette.atmosphericIntensity(state.season);
    return (base * _blend3(ritual, moon, season)).clamp(0.0, 1.0);
  }

  /// Warmth for Color.lerp toward gold [0 … 1] base blend factor.
  double warmthBlendFactor() {
    final ritual = OraclyRitualAtmosphere.warmthBias(state.ritualTime);
    final moon = OraclyMoonLighting.warmthBias(state.moonIllumination);
    final season = OraclySeasonalPalette.warmthBias(state.season);
    final combined = ritual * 0.5 + moon * 0.3 + season * 0.2;
    return (0.5 + combined).clamp(0.42, 0.58);
  }
}
