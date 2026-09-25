/// Single birth-city catalogue entry.
library;

import 'birth_chart_city_labels.dart';

class BirthChartCity {
  const BirthChartCity({
    required this.id,
    required this.nameTr,
    required this.latitude,
    required this.longitude,
    this.timezoneId = 'Europe/Istanbul',
  });

  final String id;
  final String nameTr;
  final double latitude;
  final double longitude;

  /// Stable IANA timezone for this catalogue place (not device TZ).
  final String timezoneId;

  String label({String? languageCode}) =>
      BirthChartCityLabels.of(id, nameTr, languageCode: languageCode);
}
