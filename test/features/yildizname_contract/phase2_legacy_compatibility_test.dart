/// Phase 2 — production NatalChartCalculator is tropical sun legacy only.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';

import 'truth/yildizname_structure_validators.dart';

void main() {
  const calculator = NatalChartCalculator();

  test('fidelity is tropicalSunSign', () {
    expect(calculator.fidelity, ChartCalculationFidelity.tropicalSunSign);
  });

  test('calculates sun sign only — no moon/rising/houses/aspects', () {
    final chart = calculator.calculate(
      BirthProfile(
        birthDate: DateTime(1995, 8, 15),
        birthPlace: 'İstanbul',
        birthTime: DateTime(1995, 8, 15, 14, 30),
        birthTimeKnown: true,
        latitude: 41.01,
        longitude: 28.98,
      ),
    );

    expect(chart.sun.sign, ZodiacSignId.leo);
    expect(chart.fidelity, ChartCalculationFidelity.tropicalSunSign);
    expect(chart.hasFullNatal, isFalse);
    expect(chart.moon, isNull);
    expect(chart.rising, isNull);
    expect(chart.planets, isEmpty);
    expect(chart.houses, isEmpty);
    expect(chart.aspects, isEmpty);
  });

  test('degree 0 and house 0 are legacy placeholders — not 0° Aries precision', () {
    final chart = calculator.calculate(
      BirthProfile(
        birthDate: DateTime(1990, 7, 15),
        birthPlace: 'Istanbul',
      ),
    );
    expect(
      YildiznameStructureValidators.isLegacyPlaceholderDegree(chart.sun.degree),
      isTrue,
    );
    expect(
      YildiznameStructureValidators.isLegacyPlaceholderHouse(chart.sun.house),
      isTrue,
    );
    // Do NOT treat degree==0 / house==0 as authoritative ephemeris placement.
    expect(chart.hasFullNatal, isFalse);
  });

  test('birth time and place do not create full natal', () {
    final withTimePlace = calculator.calculate(
      BirthProfile(
        birthDate: DateTime(1990, 7, 15),
        birthPlace: 'Istanbul',
        birthTime: DateTime(1990, 7, 15, 3, 0),
        birthTimeKnown: true,
        latitude: 41.0,
        longitude: 29.0,
      ),
    );
    final dateOnly = calculator.calculate(
      BirthProfile(
        birthDate: DateTime(1990, 7, 15),
        birthPlace: 'Istanbul',
      ),
    );
    expect(withTimePlace.hasFullNatal, isFalse);
    expect(withTimePlace.moon, isNull);
    expect(withTimePlace.rising, isNull);
    expect(withTimePlace.sun.sign, dateOnly.sun.sign);
    expect(withTimePlace.fidelity, ChartCalculationFidelity.tropicalSunSign);
  });
}
