/// Tasks 44–47 — E1–E4 generate; E4 still tropicalSunSign.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_cities.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence_classifier.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence_completeness.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';

BirthEvidenceCompleteness _cls(BirthProfile p) =>
    BirthEvidenceClassifier.classify(BirthEvidence.fromProfile(p));

void _assertLegacyOnly(chart) {
  expect(chart.fidelity, ChartCalculationFidelity.tropicalSunSign);
  expect(chart.moon, isNull);
  expect(chart.rising, isNull);
  expect(chart.houses, isEmpty);
  expect(chart.aspects, isEmpty);
  expect(chart.planets, isEmpty);
}

void main() {
  const calc = NatalChartCalculator();
  final d = DateTime(1990, 3, 25);
  final city = BirthChartCities.byId('ankara')!;

  test('Task 44 E1 reduced generate succeeds without natal layers', () {
    final p = BirthProfile(
      birthDate: d,
      birthPlace: '',
      birthTimeKnown: false,
      birthPlaceUnknownConfirmed: true,
    );
    expect(_cls(p), BirthEvidenceCompleteness.dateOnly);
    final chart = calc.calculate(p);
    _assertLegacyOnly(chart);
    expect(chart.sun, isNotNull);
  });

  test('Task 45 E2 date+place unknown time — no time-dependent facts', () {
    final p = BirthProfile(
      birthDate: d,
      birthPlace: city.nameTr,
      birthTimeKnown: false,
      latitude: city.latitude,
      longitude: city.longitude,
      birthPlaceId: city.id,
      timezoneId: city.timezoneId,
      timezoneResolutionStatus: BirthTimezoneStatus.resolved,
    );
    expect(_cls(p), BirthEvidenceCompleteness.dateAndPlaceNoTime);
    _assertLegacyOnly(calc.calculate(p));
  });

  test('Task 46 E3 date+time no place — no assumed timezone', () {
    final p = BirthProfile(
      birthDate: d,
      birthPlace: '',
      birthTime: DateTime(1990, 3, 25, 9, 15),
      birthTimeKnown: true,
      birthPlaceUnknownConfirmed: true,
    );
    expect(_cls(p), BirthEvidenceCompleteness.dateAndTimeNoPlace);
    expect(p.timezoneId, isNull);
    _assertLegacyOnly(calc.calculate(p));
  });

  test('Task 47 E4 evidence complete still tropicalSunSign fidelity', () {
    final p = BirthProfile(
      birthDate: d,
      birthPlace: city.nameTr,
      birthTime: DateTime(1990, 3, 25, 14, 30),
      birthTimeKnown: true,
      latitude: city.latitude,
      longitude: city.longitude,
      birthPlaceId: city.id,
      timezoneId: city.timezoneId,
      timezoneResolutionStatus: BirthTimezoneStatus.resolved,
    );
    expect(_cls(p), BirthEvidenceCompleteness.full);
    final chart = calc.calculate(p);
    _assertLegacyOnly(chart);
    expect(chart.hasFullNatal, isFalse);
  });
}
