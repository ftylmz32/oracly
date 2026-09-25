/// Phase 4 — birth instant / DST resolution.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_instant_resolution.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_instant_resolver.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';

BirthProfile _p({
  required DateTime date,
  required DateTime time,
  required String tz,
}) {
  return BirthProfile(
    birthDate: date,
    birthPlace: 'Test',
    birthTime: time,
    birthTimeKnown: true,
    latitude: 41.0,
    longitude: 29.0,
    timezoneId: tz,
    timezoneResolutionStatus: BirthTimezoneStatus.resolved,
  );
}

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('Europe/Istanbul exact civil time → UTC', () {
    final r = BirthInstantResolver.resolve(_p(
      date: DateTime(2000, 1, 1),
      time: DateTime(2000, 1, 1, 12, 0),
      tz: 'Europe/Istanbul',
    ));
    expect(r.isExact, isTrue);
    // Winter 2000 Istanbul was UTC+2 historically (IANA).
    expect(r.utc!.isUtc, isTrue);
    expect(r.utc!.hour + r.utc!.minute / 60, isNot(12));
  });

  test('America/New_York spring-forward nonexistent', () {
    // US spring forward 2006-04-02 02:00 skipped.
    final r = BirthInstantResolver.resolve(_p(
      date: DateTime(2006, 4, 2),
      time: DateTime(2006, 4, 2, 2, 30),
      tz: 'America/New_York',
    ));
    expect(r.kind, BirthInstantKind.nonexistent);
  });

  test('America/New_York fall-back ambiguous', () {
    // US fall back 2006-10-29 01:xx repeated.
    final r = BirthInstantResolver.resolve(_p(
      date: DateTime(2006, 10, 29),
      time: DateTime(2006, 10, 29, 1, 30),
      tz: 'America/New_York',
    ));
    expect(r.kind, BirthInstantKind.ambiguous);
    expect(r.candidates.length, greaterThanOrEqualTo(2));
  });

  test('future birth date unsupported', () {
    final future = DateTime.now().toUtc().add(const Duration(days: 400));
    final r = BirthInstantResolver.resolve(_p(
      date: future,
      time: DateTime(future.year, future.month, future.day, 12),
      tz: 'Europe/Berlin',
    ));
    expect(r.kind, BirthInstantKind.unsupportedDate);
  });

  test('device timezone never used — missing tz → unavailable', () {
    final r = BirthInstantResolver.resolve(BirthProfile(
      birthDate: DateTime(1990, 5, 1),
      birthPlace: 'x',
      birthTime: DateTime(1990, 5, 1, 3),
      birthTimeKnown: true,
    ));
    expect(r.kind, BirthInstantKind.unavailable);
  });
}
