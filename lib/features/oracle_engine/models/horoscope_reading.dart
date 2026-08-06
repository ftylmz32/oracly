/// OR-1140 — Horoscope reading domain model.
library;

import '../core/oracle_engine_type.dart';

class PlanetPosition {
  const PlanetPosition({
    required this.planet,
    required this.sign,
    required this.degree,
  });

  final String planet;
  final String sign;
  final double degree;
}

class HoroscopeReading {
  const HoroscopeReading({
    required this.id,
    required this.sunSign,
    required this.features,
    required this.createdAt,
    this.moonSign,
    this.ascendant,
    this.planets = const [],
  });

  final String id;
  final String sunSign;
  final Set<AstrologyFeature> features;
  final DateTime createdAt;
  final String? moonSign;
  final String? ascendant;
  final List<PlanetPosition> planets;

  Map<String, dynamic> toFacts() => {
        'id': id,
        'sunSign': sunSign,
        'moonSign': moonSign,
        'ascendant': ascendant,
        'features': features.map((f) => f.name).toList(),
        'planets': planets.map((p) => p.planet).toList(),
      };
}
