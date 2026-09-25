/// Phase 4.1 — independent retrograde fixtures (Horizons frozen; no network).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/astronomical_ephemeris_port.dart';
import 'package:oracly_new/features/birth_chart/astronomy/astronomia_ephemeris_adapter.dart';
import 'package:oracly_new/features/birth_chart/astronomy/longitude_math.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_body.dart';
import 'package:oracly_new/features/birth_chart/astronomy/retrograde_detector.dart';

import 'phase4_fixtures.dart';

/// Deterministic wrap-around fake — not used as truth for R/D dates.
class _WrapFakeEph implements AstronomicalEphemerisPort {
  _WrapFakeEph(this._lonAt);
  final double Function(DateTime utc) _lonAt;

  @override
  double longitude(NatalBody body, DateTime utc) => _lonAt(utc);

  @override
  double apparentSiderealTime(DateTime utc) => 0;

  @override
  double trueObliquity(DateTime utc) => 0.409;

  @override
  String get engineId => 'wrap-fake';

  @override
  String get engineVersion => '0';
}

void main() {
  final eph = AstronomiaEphemerisAdapter();

  double signedMotion(double tm12, double tp12) =>
      LongitudeMath.shortestSeparation(tp12, tm12);

  test('Horizons Mercury retrograde longitudes show negative motion', () {
    final m = signedMotion(
      Phase4AstronomicalFixtures.mercuryRetroTm12,
      Phase4AstronomicalFixtures.mercuryRetroTp12,
    );
    expect(m, lessThan(0));
  });

  test('Mercury retrograde date → isRetrograde true', () {
    final actual = RetrogradeDetector.isRetrograde(
      ephemeris: eph,
      body: NatalBody.mercury,
      utc: Phase4AstronomicalFixtures.mercuryRetroUtc,
    );
    // ignore: avoid_print
    print('MercR expected=true actual=$actual');
    expect(actual, isTrue);
  });

  test('Horizons Mercury direct longitudes show positive motion', () {
    final m = signedMotion(
      Phase4AstronomicalFixtures.mercuryDirectTm12,
      Phase4AstronomicalFixtures.mercuryDirectTp12,
    );
    expect(m, greaterThan(0));
  });

  test('Mercury direct date → isRetrograde false', () {
    final actual = RetrogradeDetector.isRetrograde(
      ephemeris: eph,
      body: NatalBody.mercury,
      utc: Phase4AstronomicalFixtures.mercuryDirectUtc,
    );
    // ignore: avoid_print
    print('MercD expected=false actual=$actual');
    expect(actual, isFalse);
  });

  test('wrap 359→0 remains direct; 0→359 remains retrograde', () {
    final t0 = DateTime.utc(2000, 1, 1, 12);
    final directWrap = _WrapFakeEph((utc) {
      final h = utc.difference(t0).inHours;
      if (h <= -12) return 359.0;
      if (h >= 12) return 1.0;
      return 0.0;
    });
    expect(
      RetrogradeDetector.isRetrograde(
        ephemeris: directWrap,
        body: NatalBody.mercury,
        utc: t0,
      ),
      isFalse,
    );
    final retroWrap = _WrapFakeEph((utc) {
      final h = utc.difference(t0).inHours;
      if (h <= -12) return 1.0;
      if (h >= 12) return 359.0;
      return 0.0;
    });
    expect(
      RetrogradeDetector.isRetrograde(
        ephemeris: retroWrap,
        body: NatalBody.mercury,
        utc: t0,
      ),
      isTrue,
    );
  });

  test('outer planet Jupiter retrograde → true', () {
    final m = signedMotion(
      Phase4AstronomicalFixtures.jupiterRetroTm12,
      Phase4AstronomicalFixtures.jupiterRetroTp12,
    );
    expect(m, lessThan(0));
    final actual = RetrogradeDetector.isRetrograde(
      ephemeris: eph,
      body: NatalBody.jupiter,
      utc: Phase4AstronomicalFixtures.jupiterRetroUtc,
    );
    // ignore: avoid_print
    print('JupR expected=true actual=$actual horizonsMotion=$m');
    expect(actual, isTrue);
  });

  test('outer planet Jupiter direct → false', () {
    final m = signedMotion(
      Phase4AstronomicalFixtures.jupiterDirectTm12,
      Phase4AstronomicalFixtures.jupiterDirectTp12,
    );
    expect(m, greaterThan(0));
    final actual = RetrogradeDetector.isRetrograde(
      ephemeris: eph,
      body: NatalBody.jupiter,
      utc: Phase4AstronomicalFixtures.jupiterDirectUtc,
    );
    // ignore: avoid_print
    print('JupD expected=false actual=$actual horizonsMotion=$m');
    expect(actual, isFalse);
  });
}
