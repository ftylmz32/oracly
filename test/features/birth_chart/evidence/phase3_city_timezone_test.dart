/// Task 48 — catalogue timezoneId coverage.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_cities.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_legacy_cities.dart';

void main() {
  test('Task 48 every Turkey province has Europe/Istanbul timezoneId', () {
    expect(BirthChartCities.all.length, BirthChartCities.turkeyProvinceCount);
    for (final city in BirthChartCities.all) {
      expect(city.timezoneId, isNotEmpty, reason: city.id);
      expect(city.timezoneId, 'Europe/Istanbul', reason: city.id);
    }
  });

  test('Task 48 legacy cities carry explicit non-device timezoneIds', () {
    final expected = {
      'berlin': 'Europe/Berlin',
      'london': 'Europe/London',
      'paris': 'Europe/Paris',
      'vienna': 'Europe/Vienna',
      'newyork': 'America/New_York',
    };
    expect(BirthChartLegacyCities.all.length, expected.length);
    for (final city in BirthChartLegacyCities.all) {
      expect(city.timezoneId, isNotEmpty, reason: city.id);
      expect(city.timezoneId, expected[city.id], reason: city.id);
      expect(city.timezoneId, isNot(equals('Europe/Istanbul')),
          reason: '${city.id} must stay explicit');
    }
  });

  test('Task 48 catalogue lookup preserves timezoneId', () {
    expect(BirthChartCities.byId('istanbul')!.timezoneId, 'Europe/Istanbul');
    expect(BirthChartCities.byName('Berlin')!.timezoneId, 'Europe/Berlin');
    expect(BirthChartCities.byName('Londra')!.timezoneId, 'Europe/London');
  });
}
