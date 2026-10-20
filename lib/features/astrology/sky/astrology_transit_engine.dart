/// Today's sky against one natal chart: real longitudes, real aspects.
library;

import '../../birth_chart/astronomy/astronomical_ephemeris_port.dart';
import '../../birth_chart/astronomy/longitude_math.dart';
import '../../birth_chart/models/zodiac_sign_id.dart';
import 'astrology_natal_sky.dart';

enum TransitAspect {
  conjunction(0),
  sextile(60),
  square(90),
  trine(120),
  opposition(180);

  const TransitAspect(this.angle);
  final double angle;

  TransitTone get tone => switch (this) {
        TransitAspect.conjunction => TransitTone.fusion,
        TransitAspect.sextile || TransitAspect.trine => TransitTone.flow,
        TransitAspect.square || TransitAspect.opposition => TransitTone.friction,
      };
}

/// How an aspect feels: merged intensity, easy flow, or friction.
enum TransitTone { fusion, flow, friction }

class TransitHit {
  const TransitHit({
    required this.transit,
    required this.natal,
    required this.aspect,
    required this.orb,
    required this.score,
  });

  final SkyPoint transit;
  final NatalSkyPoint natal;
  final TransitAspect aspect;
  final double orb;
  final double score;

  TransitTone get tone => aspect.tone;
  String get key => '${transit.name}.${aspect.name}.${natal.point.name}';
}

class TransitSky {
  const TransitSky({
    required this.natal,
    required this.longitudes,
    required this.hits,
  });

  final AstrologyNatalSky natal;
  final Map<SkyPoint, double> longitudes;

  /// Strongest first.
  final List<TransitHit> hits;

  ZodiacSignId signOf(SkyPoint transit) =>
      LongitudeMath.signOf(longitudes[transit]!);

  /// Whole-sign natal house a transiting body moves through, when known.
  int? houseOf(SkyPoint transit) => natal.houseOf(longitudes[transit]!);
}

abstract final class AstrologyTransitEngine {
  AstrologyTransitEngine._();

  static const transits = [
    SkyPoint.moon,
    SkyPoint.sun,
    SkyPoint.mercury,
    SkyPoint.venus,
    SkyPoint.mars,
    SkyPoint.jupiter,
    SkyPoint.saturn,
  ];

  /// Orb at local noon. The Moon's wide orb covers its travel across the day.
  static const orbs = <SkyPoint, double>{
    SkyPoint.moon: 6,
    SkyPoint.sun: 3,
    SkyPoint.mercury: 3,
    SkyPoint.venus: 3,
    SkyPoint.mars: 3,
    SkyPoint.jupiter: 2,
    SkyPoint.saturn: 2,
  };

  static const _transitWeight = <SkyPoint, double>{
    SkyPoint.moon: 1.0,
    SkyPoint.sun: 1.4,
    SkyPoint.mercury: 1.4,
    SkyPoint.venus: 1.5,
    SkyPoint.mars: 1.7,
    SkyPoint.jupiter: 2.0,
    SkyPoint.saturn: 2.2,
  };

  static const _natalWeight = <SkyPoint, double>{
    SkyPoint.sun: 3,
    SkyPoint.moon: 3,
    SkyPoint.ascendant: 3,
    SkyPoint.midheaven: 2.4,
    SkyPoint.venus: 2.2,
    SkyPoint.mars: 2.0,
    SkyPoint.mercury: 1.8,
    SkyPoint.saturn: 1.4,
    SkyPoint.jupiter: 1.2,
  };

  /// Sky at local noon of [day]; a daily reading speaks for the whole day.
  static TransitSky compute({
    required AstrologyNatalSky natal,
    required DateTime day,
    required AstronomicalEphemerisPort ephemeris,
  }) {
    final noon = DateTime(day.year, day.month, day.day, 12).toUtc();
    final longitudes = {
      for (final t in transits) t: ephemeris.longitude(t.body!, noon),
    };
    final hits = <TransitHit>[];
    for (final t in transits) {
      for (final n in natal.points) {
        final hit = _hit(t, longitudes[t]!, n);
        if (hit != null) hits.add(hit);
      }
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return TransitSky(
      natal: natal,
      longitudes: Map.unmodifiable(longitudes),
      hits: List.unmodifiable(hits),
    );
  }

  static TransitHit? _hit(SkyPoint t, double lon, NatalSkyPoint n) {
    final allowed = orbs[t]! - n.tolerance;
    if (allowed <= 0) return null;
    final sep = LongitudeMath.absSeparation(lon, n.longitude);
    for (final aspect in TransitAspect.values) {
      final orb = (sep - aspect.angle).abs();
      if (orb > allowed) continue;
      final closeness = 1 - (orb / allowed) * 0.6;
      return TransitHit(
        transit: t,
        natal: n,
        aspect: aspect,
        orb: orb,
        score: _transitWeight[t]! * _natalWeight[n.point]! * closeness,
      );
    }
    return null;
  }
}
