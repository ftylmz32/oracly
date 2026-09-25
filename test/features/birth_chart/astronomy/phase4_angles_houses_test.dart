/// Phase 4 — Asc/MC + Whole Sign + aspects + retrograde smoke.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/angle_calculator.dart';
import 'package:oracly_new/features/birth_chart/astronomy/astronomia_ephemeris_adapter.dart';
import 'package:oracly_new/features/birth_chart/astronomy/full_natal_evidence_builder.dart';
import 'package:oracly_new/features/birth_chart/astronomy/longitude_math.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_body.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_house_system.dart';
import 'package:oracly_new/features/birth_chart/astronomy/retrograde_detector.dart';
import 'package:oracly_new/features/birth_chart/astronomy/whole_sign_houses.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';

import 'phase4_fixtures.dart';

void main() {
  final eph = AstronomiaEphemerisAdapter();
  final utc = Phase4AstronomicalFixtures.j2000Utc;

  test('Asc/MC finite and self-consistent at equator Greenwich', () {
    final a = AngleCalculator.compute(
      ephemeris: eph,
      utc: utc,
      latitudeDeg: 0,
      longitudeDeg: 0,
    );
    expect(a.ascendant, inInclusiveRange(0, 360));
    expect(a.midheaven, inInclusiveRange(0, 360));
    // At φ=0, Asc and MC differ by ~90° classically (not exact always).
    expect(LongitudeMath.absSeparation(a.ascendant, a.midheaven), greaterThan(1));
  });

  test('Whole Sign houses: Asc sign = H1; MC not forced to 10', () {
    final evidence = FullNatalEvidenceBuilder.build(
      ephemeris: eph,
      utc: utc,
      latitude: 41.0082,
      longitude: 28.9784,
      fingerprint: 'test',
    );
    expect(evidence.houseSystem, NatalHouseSystem.wholeSign);
    expect(evidence.houses, hasLength(12));
    expect(evidence.houses.first.sign, evidence.ascendant!.sign);
    expect(evidence.houses.first.cuspLongitude, evidence.ascendant!.sign.signIndex * 30.0);
    // MC is an angle; its Whole Sign house follows MC sign, not forced to 10.
    final mcHouse = WholeSignHouses.houseOf(
      bodySign: evidence.midheaven!.sign,
      ascendantSign: evidence.ascendant!.sign,
    );
    expect(evidence.midheaven!.house, mcHouse);
    expect(
      WholeSignHouses.isEqualHouseConfused(
        ascLongitude: evidence.ascendant!.longitude,
        ascSign: evidence.ascendant!.sign,
      ),
      LongitudeMath.degreeWithinSign(evidence.ascendant!.longitude) > 0.001,
    );
  });

  test('full E4 evidence has all bodies + aspects + fidelity', () {
    final evidence = FullNatalEvidenceBuilder.build(
      ephemeris: eph,
      utc: utc,
      latitude: 51.5074,
      longitude: -0.1278,
      fingerprint: 'e4',
    );
    expect(evidence.fidelity, ChartCalculationFidelity.fullNatalEphemeris);
    expect(evidence.placements, hasLength(NatalBody.values.length));
    for (final p in evidence.placements) {
      expect(p.longitude, isNotNull);
      expect(p.sign, LongitudeMath.signOf(p.longitude!));
      expect(p.house, inInclusiveRange(1, 12));
    }
    expect(evidence.aspects, isNotEmpty);
    expect(evidence.ascendant, isNotNull);
    expect(evidence.midheaven, isNotNull);
  });

  test('Mercury retrograde detector returns bool; Sun null', () {
    expect(
      RetrogradeDetector.isRetrograde(
        ephemeris: eph,
        body: NatalBody.sun,
        utc: utc,
      ),
      isNull,
    );
    expect(
      RetrogradeDetector.isRetrograde(
        ephemeris: eph,
        body: NatalBody.mercury,
        utc: utc,
      ),
      isA<bool>(),
    );
  });
}
