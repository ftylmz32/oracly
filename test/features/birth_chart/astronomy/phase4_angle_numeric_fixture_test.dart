/// Phase 4.1 — independent Asc/MC numeric fixtures (external expected).
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/angle_calculator.dart';
import 'package:oracly_new/features/birth_chart/astronomy/astronomia_ephemeris_adapter.dart';
import 'package:oracly_new/features/birth_chart/astronomy/longitude_math.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_body.dart';

import 'phase4_fixtures.dart';

void main() {
  final eph = AstronomiaEphemerisAdapter();
  const tol = Phase4AstronomicalFixtures.angleTolDeg;

  test('ASC fixture 1 — Chicago independent Asc ≈ 82.562°', () {
    final a = AngleCalculator.compute(
      ephemeris: eph,
      utc: Phase4AstronomicalFixtures.chicagoAscUtc,
      latitudeDeg: Phase4AstronomicalFixtures.chicagoLat,
      longitudeDeg: Phase4AstronomicalFixtures.chicagoLon,
    );
    final err = LongitudeMath.absSeparation(
      a.ascendant,
      Phase4AstronomicalFixtures.chicagoExpectedAsc,
    );
    // ignore: avoid_print
    print(
      'ASC1 expected=${Phase4AstronomicalFixtures.chicagoExpectedAsc} '
      'actual=${a.ascendant} err=$err tol=$tol',
    );
    expect(err, lessThanOrEqualTo(tol));
  });

  test('ASC fixture 2 — São Paulo southern Asc ≈ 159.44°', () {
    final a = AngleCalculator.compute(
      ephemeris: eph,
      utc: Phase4AstronomicalFixtures.saoPauloUtc,
      latitudeDeg: Phase4AstronomicalFixtures.saoPauloLat,
      longitudeDeg: Phase4AstronomicalFixtures.saoPauloLon,
    );
    final err = LongitudeMath.absSeparation(
      a.ascendant,
      Phase4AstronomicalFixtures.saoPauloExpectedAsc,
    );
    // ignore: avoid_print
    print(
      'ASC2 expected=${Phase4AstronomicalFixtures.saoPauloExpectedAsc} '
      'actual=${a.ascendant} err=$err tol=$tol',
    );
    expect(err, lessThanOrEqualTo(tol));
  });

  test('MC fixture 1 — Enschede RadixPro MC ≈ 9.6299°', () {
    final a = AngleCalculator.compute(
      ephemeris: eph,
      utc: Phase4AstronomicalFixtures.enschedeUtc,
      latitudeDeg: Phase4AstronomicalFixtures.enschedeLat,
      longitudeDeg: Phase4AstronomicalFixtures.enschedeLon,
    );
    final err = LongitudeMath.absSeparation(
      a.midheaven,
      Phase4AstronomicalFixtures.enschedeExpectedMc,
    );
    // ignore: avoid_print
    print(
      'MC1 expected=${Phase4AstronomicalFixtures.enschedeExpectedMc} '
      'actual=${a.midheaven} err=$err tol=$tol',
    );
    expect(err, lessThanOrEqualTo(tol));
  });

  test('MC fixture 2 — São Paulo J-Kit MC ≈ 75.76°', () {
    final a = AngleCalculator.compute(
      ephemeris: eph,
      utc: Phase4AstronomicalFixtures.saoPauloUtc,
      latitudeDeg: Phase4AstronomicalFixtures.saoPauloLat,
      longitudeDeg: Phase4AstronomicalFixtures.saoPauloLon,
    );
    final err = LongitudeMath.absSeparation(
      a.midheaven,
      Phase4AstronomicalFixtures.saoPauloExpectedMc,
    );
    // ignore: avoid_print
    print(
      'MC2 expected=${Phase4AstronomicalFixtures.saoPauloExpectedMc} '
      'actual=${a.midheaven} err=$err tol=$tol',
    );
    expect(err, lessThanOrEqualTo(tol));
  });

  test('sunrise sanity — Asc near Sun at Greenwich equinox sunrise', () {
    final utc = Phase4AstronomicalFixtures.greenwichSunriseUtc;
    final a = AngleCalculator.compute(
      ephemeris: eph,
      utc: utc,
      latitudeDeg: Phase4AstronomicalFixtures.greenwichSunriseLat,
      longitudeDeg: Phase4AstronomicalFixtures.greenwichSunriseLon,
    );
    final sun = eph.longitude(NatalBody.sun, utc);
    final err = LongitudeMath.absSeparation(a.ascendant, sun);
    final desc = LongitudeMath.normalize(a.ascendant + 180);
    final descErr = LongitudeMath.absSeparation(desc, sun);
    // ignore: avoid_print
    print('SUNRISE Asc=${a.ascendant} Sun=$sun err=$err descErr=$descErr');
    expect(err, lessThanOrEqualTo(Phase4AstronomicalFixtures.sunriseAscSunTolDeg));
    // Descendant must NOT be the closer intersection (no 180° flip).
    expect(err, lessThan(descErr));
  });

  test('MC RAMC quadrant reference — atan2 vs atan+branch', () {
    const eps = 23.4392794444444 * math.pi / 180;
    for (final ramcDeg in [0.0, 90.0, 180.0, 270.0, 45.0, 225.0]) {
      final t = ramcDeg * math.pi / 180;
      final prod = LongitudeMath.normalize(
        math.atan2(math.sin(t), math.cos(t) * math.cos(eps)) * 180 / math.pi,
      );
      // Independent reference: atan + classical quadrant rules (Meeus).
      var ref = math.atan(math.sin(t) / (math.cos(t) * math.cos(eps))) *
          180 /
          math.pi;
      if (math.cos(t) < 0) {
        ref += 180;
      } else if (ref < 0) {
        ref += 360;
      }
      ref = LongitudeMath.normalize(ref);
      final err = LongitudeMath.absSeparation(prod, ref);
      // ignore: avoid_print
      print('RAMC=$ramcDeg prod=$prod ref=$ref err=$err');
      expect(err, lessThan(1e-9));
    }
  });
}
