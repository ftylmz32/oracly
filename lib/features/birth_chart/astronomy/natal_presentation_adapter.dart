/// Phase 4 — adapt structured evidence → legacy presentation Planet/House.
library;

import '../models/aspect.dart';
import '../models/house.dart';
import '../models/planet.dart';
import '../models/zodiac_sign_id.dart';
import 'astronomical_fact_certainty.dart';
import 'natal_body.dart';
import 'natal_chart_evidence.dart';
import 'natal_placement.dart';

abstract final class NatalPresentationAdapter {
  NatalPresentationAdapter._();

  static PlanetId? toPlanetId(NatalBody body) => switch (body) {
        NatalBody.sun => PlanetId.sun,
        NatalBody.moon => PlanetId.moon,
        NatalBody.mercury => PlanetId.mercury,
        NatalBody.venus => PlanetId.venus,
        NatalBody.mars => PlanetId.mars,
        NatalBody.jupiter => PlanetId.jupiter,
        NatalBody.saturn => PlanetId.saturn,
        NatalBody.uranus => PlanetId.uranus,
        NatalBody.neptune => PlanetId.neptune,
        NatalBody.pluto => PlanetId.pluto,
      };

  static Planet? exactPlanet(NatalPlacement p) {
    if (p.certainty != AstronomicalFactCertainty.exact) return null;
    if (p.longitude == null || p.degreeWithinSign == null || p.house == null) {
      return null;
    }
    final id = toPlanetId(p.body);
    if (id == null) return null;
    final sign = p.sign;
    if (sign == null) return null;
    return Planet(
      id: id,
      sign: sign,
      degree: p.degreeWithinSign!,
      house: p.house!,
    );
  }

  static List<Planet> planets(NatalChartEvidence e) {
    final out = <Planet>[];
    for (final p in e.placements) {
      if (p.body == NatalBody.sun || p.body == NatalBody.moon) continue;
      final planet = exactPlanet(p);
      if (planet != null) out.add(planet);
    }
    return out;
  }

  static List<House> houses(NatalChartEvidence e) => [
        for (final h in e.houses)
          House(number: h.number, sign: h.sign, cuspDegree: 0),
      ];

  static List<Aspect> aspects(NatalChartEvidence e) {
    final out = <Aspect>[];
    for (final a in e.aspects) {
      final pa = toPlanetId(a.bodyA);
      final pb = toPlanetId(a.bodyB);
      if (pa == null || pb == null) continue;
      out.add(Aspect(
        planetA: pa,
        planetB: pb,
        type: a.type,
        orb: a.orb,
      ));
    }
    return out;
  }
}
