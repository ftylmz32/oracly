/// Phase 4 — evidence routing E1–E4 + reduced interval + persistence.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/birth_chart/astronomy/evidence_aware_natal_calculator.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_body.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_calculation_error.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);
  final calc = EvidenceAwareNatalChartCalculator();

  test('E1 date-only → tropicalSunSign', () {
    final chart = calc.calculate(BirthProfile(
      birthDate: DateTime(1990, 6, 15),
      birthPlace: '',
      birthTimeKnown: false,
      birthPlaceUnknownConfirmed: true,
    ));
    expect(chart.fidelity, ChartCalculationFidelity.tropicalSunSign);
    expect(chart.moon, isNull);
    expect(chart.rising, isNull);
    expect(chart.houses, isEmpty);
    expect(chart.natalEvidence, isNull);
  });

  test('E3 known time no place → tropicalSunSign', () {
    final chart = calc.calculate(BirthProfile(
      birthDate: DateTime(1990, 6, 15),
      birthPlace: '',
      birthTime: DateTime(1990, 6, 15, 14, 30),
      birthTimeKnown: true,
      birthPlaceUnknownConfirmed: true,
    ));
    expect(chart.fidelity, ChartCalculationFidelity.tropicalSunSign);
    expect(chart.natalEvidence, isNull);
  });

  test('E2 place+tz unknown time → reducedNatal, no Asc/MC/houses/degrees', () {
    final chart = calc.calculate(BirthProfile(
      birthDate: DateTime(1990, 6, 15),
      birthPlace: 'İstanbul',
      birthPlaceId: 'tr_34',
      birthTimeKnown: false,
      latitude: 41.0082,
      longitude: 28.9784,
      timezoneId: 'Europe/Istanbul',
      timezoneResolutionStatus: BirthTimezoneStatus.resolved,
    ));
    expect(chart.fidelity, ChartCalculationFidelity.reducedNatal);
    expect(chart.natalEvidence, isNotNull);
    expect(chart.rising, isNull);
    expect(chart.midheaven, isNull);
    expect(chart.houses, isEmpty);
    expect(chart.aspects, isEmpty);
    for (final p in chart.natalEvidence!.placements) {
      expect(p.longitude, isNull);
      expect(p.degreeWithinSign, isNull);
      expect(p.retrograde, isNull);
      expect(p.house, isNull);
    }
  });

  test('E4 exact → fullNatalEphemeris persist round-trip', () {
    final profile = BirthProfile(
      birthDate: DateTime(2000, 1, 1),
      birthPlace: 'İstanbul',
      birthPlaceId: 'tr_34',
      birthTime: DateTime(2000, 1, 1, 12, 0),
      birthTimeKnown: true,
      latitude: 41.0082,
      longitude: 28.9784,
      timezoneId: 'Europe/Istanbul',
      timezoneResolutionStatus: BirthTimezoneStatus.resolved,
    );
    final chart = calc.calculate(profile);
    expect(chart.fidelity, ChartCalculationFidelity.fullNatalEphemeris);
    expect(chart.moon, isNotNull);
    expect(chart.rising, isNotNull);
    expect(chart.midheaven, isNotNull);
    expect(chart.houses, hasLength(12));
    expect(chart.natalEvidence!.placements, hasLength(NatalBody.values.length));
    final json = chart.toJson();
    final back = BirthChart.fromJson(json);
    expect(back.fidelity, ChartCalculationFidelity.fullNatalEphemeris);
    expect(back.natalEvidence!.metadata.evidenceFingerprint,
        chart.natalEvidence!.metadata.evidenceFingerprint);
    expect(back.midheaven!.sign, chart.midheaven!.sign);
  });

  test('E4 nonexistent local time throws typed error', () {
    expect(
      () => calc.calculate(BirthProfile(
        birthDate: DateTime(2006, 4, 2),
        birthPlace: 'NYC',
        birthTime: DateTime(2006, 4, 2, 2, 30),
        birthTimeKnown: true,
        latitude: 40.7,
        longitude: -74.0,
        timezoneId: 'America/New_York',
        timezoneResolutionStatus: BirthTimezoneStatus.resolved,
      )),
      throwsA(isA<NatalNonexistentLocalTimeException>()),
    );
  });

  test('legacy tropical JSON without natalEvidence decodes', () {
    final json = {
      'id': 'legacy',
      'profile': {
        'birthDate': '1990-01-01T00:00:00.000',
        'birthPlace': 'Ankara',
        'birthTimeKnown': false,
      },
      'sun': {'id': 'sun', 'sign': 'capricorn', 'degree': 0, 'house': 0},
      'planets': [],
      'houses': [],
      'aspects': [],
      'elementBalance': {'fire': 0, 'earth': 1, 'air': 0, 'water': 0},
      'dominantEnergy': {
        'primaryElement': 'earth',
        'primaryModality': 'cardinal',
        'label': 'x',
        'summary': 'y',
      },
      'lifeThemes': [],
      'insights': [],
      'generatedAt': '2020-01-01T00:00:00.000',
      'precision': 'partialNoTime',
      'fidelity': 'tropicalSunSign',
    };
    final chart = BirthChart.fromJson(json);
    expect(chart.natalEvidence, isNull);
    expect(chart.midheaven, isNull);
    expect(chart.sun.degree, 0);
    expect(chart.sun.house, 0);
    expect(chart.fidelity, ChartCalculationFidelity.tropicalSunSign);
  });
}
