/// SPRINT-002 — Yıldızname chart model (sun-sign until full natal exists).
library;

import 'aspect.dart';
import 'birth_profile.dart';
import 'chart_insight.dart';
import 'dominant_energy.dart';
import 'element_balance.dart';
import 'house.dart';
import 'life_theme.dart';
import 'chart_fidelity.dart';
import 'planet.dart';

enum ChartPrecision {
  full,
  partialNoTime,
}

class BirthChart {
  const BirthChart({
    required this.id,
    required this.profile,
    required this.sun,
    required this.planets,
    required this.houses,
    required this.aspects,
    required this.elementBalance,
    required this.dominantEnergy,
    required this.lifeThemes,
    required this.insights,
    required this.generatedAt,
    this.moon,
    this.rising,
    this.precision = ChartPrecision.partialNoTime,
    this.fidelity = ChartCalculationFidelity.tropicalSunSign,
  });

  final String id;
  final BirthProfile profile;
  final Planet sun;
  final Planet? moon;
  final Planet? rising;
  final List<Planet> planets;
  final List<House> houses;
  final List<Aspect> aspects;
  final ElementBalance elementBalance;
  final DominantEnergy dominantEnergy;
  final List<LifeTheme> lifeThemes;
  final List<ChartInsight> insights;
  final DateTime generatedAt;
  final ChartPrecision precision;
  final ChartCalculationFidelity fidelity;

  bool get hasFullNatal =>
      fidelity == ChartCalculationFidelity.fullNatalEphemeris;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile': profile.toJson(),
        'sun': sun.toJson(),
        if (moon != null) 'moon': moon!.toJson(),
        if (rising != null) 'rising': rising!.toJson(),
        'planets': planets.map((p) => p.toJson()).toList(),
        'houses': houses.map((h) => h.toJson()).toList(),
        'aspects': aspects.map((a) => a.toJson()).toList(),
        'elementBalance': elementBalance.toJson(),
        'dominantEnergy': dominantEnergy.toJson(),
        'lifeThemes': lifeThemes.map((t) => t.toJson()).toList(),
        'insights': insights.map((i) => i.toJson()).toList(),
        'generatedAt': generatedAt.toIso8601String(),
        'precision': precision.name,
        'fidelity': fidelity.name,
      };

  factory BirthChart.fromJson(Map<String, dynamic> json) {
    return BirthChart(
      id: json['id'] as String,
      profile: BirthProfile.fromJson(json['profile'] as Map<String, dynamic>),
      sun: Planet.fromJson(json['sun'] as Map<String, dynamic>),
      moon: json['moon'] != null
          ? Planet.fromJson(json['moon'] as Map<String, dynamic>)
          : null,
      rising: json['rising'] != null
          ? Planet.fromJson(json['rising'] as Map<String, dynamic>)
          : null,
      planets: (json['planets'] as List<dynamic>? ?? const [])
          .map((e) => Planet.fromJson(e as Map<String, dynamic>))
          .toList(),
      houses: (json['houses'] as List<dynamic>? ?? const [])
          .map((e) => House.fromJson(e as Map<String, dynamic>))
          .toList(),
      aspects: (json['aspects'] as List<dynamic>? ?? const [])
          .map((e) => Aspect.fromJson(e as Map<String, dynamic>))
          .toList(),
      elementBalance: ElementBalance.fromJson(
        json['elementBalance'] as Map<String, dynamic>,
      ),
      dominantEnergy: DominantEnergy.fromJson(
        json['dominantEnergy'] as Map<String, dynamic>,
      ),
      lifeThemes: (json['lifeThemes'] as List<dynamic>? ?? const [])
          .map((e) => LifeTheme.fromJson(e as Map<String, dynamic>))
          .toList(),
      insights: (json['insights'] as List<dynamic>? ?? const [])
          .map((e) => ChartInsight.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      precision: ChartPrecision.values.byName(
        json['precision'] as String? ?? ChartPrecision.partialNoTime.name,
      ),
      fidelity: ChartCalculationFidelity.values.byName(
        json['fidelity'] as String? ??
            ChartCalculationFidelity.tropicalSunSign.name,
      ),
    );
  }
}

/// Future-ready hooks for transits and forecasts.
class ChartForecastContext {
  const ChartForecastContext({
    required this.chart,
    required this.asOf,
  });

  final BirthChart chart;
  final DateTime asOf;
}

abstract class TransitCalculationPort {
  Future<List<Aspect>> dailyTransits({
    required BirthChart chart,
    required DateTime date,
  });
}

abstract class LunarPhasePort {
  String phaseLabel({required DateTime date});
}
