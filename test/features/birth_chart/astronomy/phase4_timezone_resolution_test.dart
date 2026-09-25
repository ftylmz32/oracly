/// Phase 4 — historical IANA timezone regressions.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_instant_resolver.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  BirthProfile profile(DateTime date, int h, int m, String zone) => BirthProfile(
        birthDate: date,
        birthPlace: 'x',
        birthTime: DateTime(date.year, date.month, date.day, h, m),
        birthTimeKnown: true,
        latitude: 1,
        longitude: 1,
        timezoneId: zone,
        timezoneResolutionStatus: BirthTimezoneStatus.resolved,
      );

  test('Turkey winter 2010 uses historical UTC+2 not permanent +3', () {
    final r = BirthInstantResolver.resolve(
      profile(DateTime(2010, 1, 15), 12, 0, 'Europe/Istanbul'),
    );
    expect(r.isExact, isTrue);
    // 12:00 local EET (+2) → 10:00 UTC
    expect(r.utc, DateTime.utc(2010, 1, 15, 10, 0));
  });

  test('Berlin / London / New_York DST summer offsets', () {
    final berlin = BirthInstantResolver.resolve(
      profile(DateTime(2015, 7, 1), 12, 0, 'Europe/Berlin'),
    );
    expect(berlin.utc, DateTime.utc(2015, 7, 1, 10, 0)); // CEST +2

    final london = BirthInstantResolver.resolve(
      profile(DateTime(2015, 7, 1), 12, 0, 'Europe/London'),
    );
    expect(london.utc, DateTime.utc(2015, 7, 1, 11, 0)); // BST +1

    final nyc = BirthInstantResolver.resolve(
      profile(DateTime(2015, 7, 1), 12, 0, 'America/New_York'),
    );
    expect(nyc.utc, DateTime.utc(2015, 7, 1, 16, 0)); // EDT -4
  });

  test('never calls setLocalLocation for birth resolution', () {
    // Birth path uses explicit Location only; local may be anything.
    final before = tz.local.name;
    BirthInstantResolver.resolve(
      profile(DateTime(2000, 6, 1), 8, 0, 'Europe/Berlin'),
    );
    expect(tz.local.name, before);
  });
}
