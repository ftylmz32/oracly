/// Tasks 62–63 — OR/share firewall: no lat/lon/timezoneId/ownerId.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_natal.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_cities.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';

void main() {
  final city = BirthChartCities.byId('istanbul')!;
  final profile = BirthProfile(
    birthDate: DateTime(1990, 3, 25),
    birthPlace: city.nameTr,
    birthTime: DateTime(1990, 3, 25, 9, 15),
    birthTimeKnown: true,
    latitude: city.latitude,
    longitude: city.longitude,
    birthPlaceId: city.id,
    timezoneId: city.timezoneId,
    timezoneResolutionStatus: BirthTimezoneStatus.resolved,
  );

  test('Task 63 birthLine keeps date/time/place only', () {
    final line = OracleReadingContextNatal.birthLine(profile);
    expect(line, contains('25.3.1990'));
    expect(line, contains('09:15'));
    expect(line, contains('İstanbul'));
    expect(line, isNot(contains('latitude')));
    expect(line, isNot(contains('longitude')));
    expect(line, isNot(contains('timezoneId')));
    expect(line, isNot(contains('ownerId')));
    expect(line, isNot(contains('Europe/Istanbul')));
    expect(line, isNot(contains(city.latitude.toString())));
    expect(line, isNot(contains(city.longitude.toString())));
    expect(line, isNot(contains(city.id)));
  });

  test('Task 62 share-ish OR birthChart context excludes internals', () {
    final ctx = OracleReadingContextNatal.birthChart(
      id: 'chart_x',
      sunLabel: 'Koç',
      interpretation: 'Sakin bir yansıma.',
      profile: profile,
      summary: 'Özet',
    );
    final blobs = [
      ctx.cardsSummary,
      ctx.interpretationSummary,
      ctx.fullInterpretation,
      ctx.readingTitle,
      ctx.spreadLabel,
    ].join('\n');
    expect(blobs, isNot(contains('Europe/Istanbul')));
    expect(blobs, isNot(contains('timezoneId')));
    expect(blobs, isNot(contains('ownerId')));
    expect(blobs, isNot(contains(city.latitude.toString())));
    expect(blobs, isNot(contains(city.longitude.toString())));
    expect(blobs, contains('İstanbul'));
    expect(blobs, contains('Koç'));
  });
}
