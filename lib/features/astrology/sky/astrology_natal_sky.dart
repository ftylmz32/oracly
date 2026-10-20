/// The natal points a daily reading may honestly use for one person.
///
/// A full chart contributes its exact placements and angles. Without an exact
/// birth instant, slow bodies are taken at the birth day's local noon with a
/// tolerance of half their daily motion; the Moon and the angles are left out
/// because the day alone cannot fix them.
library;

import 'package:timezone/timezone.dart' as tz;

import '../../birth_chart/astronomy/astronomical_ephemeris_port.dart';
import '../../birth_chart/astronomy/astronomical_fact_certainty.dart';
import '../../birth_chart/astronomy/birth_timezone_database.dart';
import '../../birth_chart/astronomy/longitude_math.dart';
import '../../birth_chart/astronomy/natal_body.dart';
import '../../birth_chart/astronomy/natal_chart_evidence.dart';
import '../../birth_chart/models/birth_profile.dart';
import '../../birth_chart/models/chart_fidelity.dart';
import '../../birth_chart/models/zodiac_sign_id.dart';

enum SkyPoint {
  sun,
  moon,
  mercury,
  venus,
  mars,
  jupiter,
  saturn,
  ascendant,
  midheaven;

  NatalBody? get body => switch (this) {
        SkyPoint.sun => NatalBody.sun,
        SkyPoint.moon => NatalBody.moon,
        SkyPoint.mercury => NatalBody.mercury,
        SkyPoint.venus => NatalBody.venus,
        SkyPoint.mars => NatalBody.mars,
        SkyPoint.jupiter => NatalBody.jupiter,
        SkyPoint.saturn => NatalBody.saturn,
        _ => null,
      };
}

/// Fire, earth, air, water — the zodiac cycles through them in that order.
enum SkyElement { fire, earth, air, water }

SkyElement elementOf(ZodiacSignId sign) => SkyElement.values[sign.index % 4];

class NatalSkyPoint {
  const NatalSkyPoint({
    required this.point,
    required this.longitude,
    this.tolerance = 0,
    this.house,
  });

  final SkyPoint point;
  final double longitude;

  /// Degrees the true position may differ by (0 for an exact chart).
  final double tolerance;
  final int? house;

  ZodiacSignId get sign => LongitudeMath.signOf(longitude);
}

enum NatalSkyDepth {
  /// Exact birth instant and place: planets, Moon, ascendant, midheaven.
  full,

  /// Birth day only: slow planets within a small tolerance.
  dayOnly,
}

class AstrologyNatalSky {
  const AstrologyNatalSky({
    required this.depth,
    required this.points,
    this.moonSign,
  });

  final NatalSkyDepth depth;
  final List<NatalSkyPoint> points;

  /// Known even without exact time when the Moon stayed in one sign all day.
  final ZodiacSignId? moonSign;

  NatalSkyPoint? of(SkyPoint point) {
    for (final p in points) {
      if (p.point == point) return p;
    }
    return null;
  }

  ZodiacSignId get sunSign => of(SkyPoint.sun)!.sign;
  ZodiacSignId? get ascendantSign => of(SkyPoint.ascendant)?.sign;
  bool get hasHouses => of(SkyPoint.ascendant) != null;

  /// Whole-sign house of [longitude], counted from the ascendant sign.
  int? houseOf(double longitude) {
    final asc = of(SkyPoint.ascendant);
    if (asc == null) return null;
    final from = asc.sign.index;
    final to = LongitudeMath.signOf(longitude).index;
    return (to - from + 12) % 12 + 1;
  }

  /// Half the fastest typical daily motion of each body, in degrees.
  static const dayTolerance = <SkyPoint, double>{
    SkyPoint.sun: 0.5,
    SkyPoint.mercury: 1.1,
    SkyPoint.venus: 0.65,
    SkyPoint.mars: 0.4,
    SkyPoint.jupiter: 0.12,
    SkyPoint.saturn: 0.07,
  };

  static AstrologyNatalSky? from({
    required BirthProfile? profile,
    required NatalChartEvidence? evidence,
    required AstronomicalEphemerisPort ephemeris,
  }) {
    if (profile == null) return null;
    final full = _full(evidence);
    if (full != null) return full;
    try {
      return _dayOnly(profile, evidence, ephemeris);
    } catch (_) {
      return null;
    }
  }

  static AstrologyNatalSky? _full(NatalChartEvidence? evidence) {
    if (evidence == null ||
        evidence.fidelity != ChartCalculationFidelity.fullNatalEphemeris) {
      return null;
    }
    final asc = evidence.ascendant;
    final mc = evidence.midheaven;
    if (asc == null || mc == null) return null;
    final points = <NatalSkyPoint>[];
    for (final point in SkyPoint.values) {
      final body = point.body;
      if (body == null) continue;
      final placement = evidence.placements
          .where((p) =>
              p.body == body &&
              p.longitude != null &&
              p.certainty == AstronomicalFactCertainty.exact)
          .firstOrNull;
      if (placement == null) return null;
      points.add(NatalSkyPoint(
        point: point,
        longitude: placement.longitude!,
        house: placement.house,
      ));
    }
    points
      ..add(NatalSkyPoint(point: SkyPoint.ascendant, longitude: asc.longitude))
      ..add(NatalSkyPoint(point: SkyPoint.midheaven, longitude: mc.longitude));
    return AstrologyNatalSky(
      depth: NatalSkyDepth.full,
      points: List.unmodifiable(points),
      moonSign: LongitudeMath.signOf(points[1].longitude),
    );
  }

  static AstrologyNatalSky _dayOnly(
    BirthProfile profile,
    NatalChartEvidence? evidence,
    AstronomicalEphemerisPort ephemeris,
  ) {
    final noon = _birthNoonUtc(profile);
    final points = <NatalSkyPoint>[
      for (final entry in dayTolerance.entries)
        NatalSkyPoint(
          point: entry.key,
          longitude: ephemeris.longitude(entry.key.body!, noon),
          tolerance: entry.value,
        ),
    ];
    return AstrologyNatalSky(
      depth: NatalSkyDepth.dayOnly,
      points: List.unmodifiable(points),
      moonSign: _stableMoon(evidence),
    );
  }

  static DateTime _birthNoonUtc(BirthProfile profile) {
    final d = profile.birthDate;
    final zone = profile.timezoneId;
    if (zone != null && zone.isNotEmpty) {
      try {
        final loc = BirthTimezoneDatabase.locationOf(zone);
        return tz.TZDateTime(loc, d.year, d.month, d.day, 12).toUtc();
      } catch (_) {}
    }
    return DateTime.utc(d.year, d.month, d.day, 12);
  }

  static ZodiacSignId? _stableMoon(NatalChartEvidence? evidence) {
    if (evidence == null) return null;
    for (final p in evidence.placements) {
      if (p.body != NatalBody.moon || p.sign == null) continue;
      if (p.certainty == AstronomicalFactCertainty.exact ||
          p.certainty == AstronomicalFactCertainty.intervalStable) {
        return p.sign;
      }
    }
    return null;
  }
}
