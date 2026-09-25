/// Phase 4 — ephemeris vs authoritative Horizons / Meeus fixtures.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/astronomia_ephemeris_adapter.dart';
import 'package:oracly_new/features/birth_chart/astronomy/longitude_math.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_body.dart';

import 'phase4_fixtures.dart';

void main() {
  final eph = AstronomiaEphemerisAdapter();

  double err(NatalBody body, double expected) {
    final got = eph.longitude(body, Phase4AstronomicalFixtures.j2000Utc);
    return LongitudeMath.absSeparation(got, expected);
  }

  test('Sun J2000 vs Horizons within 0.05°', () {
    expect(
      err(NatalBody.sun, Phase4AstronomicalFixtures.horizonsJ2000['sun']!),
      lessThanOrEqualTo(Phase4AstronomicalFixtures.sunTolDeg),
    );
  });

  test('Moon J2000 vs Horizons within 0.10°', () {
    expect(
      err(NatalBody.moon, Phase4AstronomicalFixtures.horizonsJ2000['moon']!),
      lessThanOrEqualTo(Phase4AstronomicalFixtures.moonTolDeg),
    );
  });

  test('Mercury–Pluto J2000 vs Horizons within 0.05°', () {
    final bodies = {
      NatalBody.mercury: 'mercury',
      NatalBody.venus: 'venus',
      NatalBody.mars: 'mars',
      NatalBody.jupiter: 'jupiter',
      NatalBody.saturn: 'saturn',
      NatalBody.uranus: 'uranus',
      NatalBody.neptune: 'neptune',
      NatalBody.pluto: 'pluto',
    };
    for (final e in bodies.entries) {
      final d = err(e.key, Phase4AstronomicalFixtures.horizonsJ2000[e.value]!);
      expect(
        d,
        lessThanOrEqualTo(Phase4AstronomicalFixtures.planetTolDeg),
        reason: '${e.key} err=$d',
      );
    }
  });

  test('Meeus Sun 1992-10-13 apparent within tolerance', () {
    final got = eph.longitude(
      NatalBody.sun,
      Phase4AstronomicalFixtures.meeusSunUtc,
    );
    expect(
      LongitudeMath.absSeparation(
        got,
        Phase4AstronomicalFixtures.meeusSunApparentDeg,
      ),
      lessThanOrEqualTo(Phase4AstronomicalFixtures.sunTolDeg),
    );
  });
}
