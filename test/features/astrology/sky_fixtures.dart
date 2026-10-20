/// Synthetic people for sky-reading tests. No real customer data.
library;

import 'package:oracly_new/features/astrology/sky/astrology_natal_sky.dart';
import 'package:oracly_new/features/birth_chart/astronomy/astronomia_ephemeris_adapter.dart';
import 'package:oracly_new/features/birth_chart/astronomy/evidence_aware_natal_calculator.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_cities.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';

final skyEphemeris = AstronomiaEphemerisAdapter();

BirthProfile cityProfile(
  DateTime date, {
  required String cityId,
  int? hour,
  int minute = 0,
}) {
  final city = BirthChartCities.byId(cityId)!;
  return BirthProfile(
    birthDate: date,
    birthPlace: city.nameTr,
    birthTime: hour == null
        ? null
        : DateTime(date.year, date.month, date.day, hour, minute),
    birthTimeKnown: hour != null,
    latitude: city.latitude,
    longitude: city.longitude,
    birthPlaceId: city.id,
    timezoneId: city.timezoneId,
    timezoneResolutionStatus: BirthTimezoneStatus.resolved,
  );
}

class SkyPerson {
  SkyPerson(this.name, this.profile)
      : chart = EvidenceAwareNatalChartCalculator().calculate(profile);

  final String name;
  final BirthProfile profile;
  final BirthChart chart;

  AstrologyNatalSky get sky => AstrologyNatalSky.from(
        profile: profile,
        evidence: chart.natalEvidence,
        ephemeris: skyEphemeris,
      )!;
}

/// Aries, full chart (time + city).
final ayse = SkyPerson(
  'Ayşe',
  cityProfile(DateTime(1992, 4, 5), cityId: 'istanbul', hour: 14, minute: 30),
);

/// Aries too, but no birth time: day-only positions, no Moon or ascendant.
final mehmet = SkyPerson(
  'Mehmet',
  cityProfile(DateTime(1988, 4, 12), cityId: 'ankara'),
);

/// Libra, full chart.
final zeynep = SkyPerson(
  'Zeynep',
  cityProfile(DateTime(1995, 10, 20), cityId: 'izmir', hour: 7, minute: 15),
);

final skyPeople = [ayse, mehmet, zeynep];
