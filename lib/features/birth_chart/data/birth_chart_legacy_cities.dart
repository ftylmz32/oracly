/// Legacy resolve-only birth cities (not in picker).
library;

import 'birth_chart_city.dart';

abstract final class BirthChartLegacyCities {
  BirthChartLegacyCities._();

  static const List<BirthChartCity> all = [
    BirthChartCity(
      id: 'berlin',
      nameTr: 'Berlin',
      latitude: 52.52,
      longitude: 13.40,
      timezoneId: 'Europe/Berlin',
    ),
    BirthChartCity(
      id: 'london',
      nameTr: 'Londra',
      latitude: 51.51,
      longitude: -0.13,
      timezoneId: 'Europe/London',
    ),
    BirthChartCity(
      id: 'paris',
      nameTr: 'Paris',
      latitude: 48.86,
      longitude: 2.35,
      timezoneId: 'Europe/Paris',
    ),
    BirthChartCity(
      id: 'vienna',
      nameTr: 'Viyana',
      latitude: 48.21,
      longitude: 16.37,
      timezoneId: 'Europe/Vienna',
    ),
    BirthChartCity(
      id: 'newyork',
      nameTr: 'New York',
      latitude: 40.71,
      longitude: -74.01,
      timezoneId: 'America/New_York',
    ),
  ];
}
