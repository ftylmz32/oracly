import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/home_personal_copy.dart';
import 'package:oracly_new/core/universe/oracly_ritual_time.dart';
import 'package:oracly_new/core/universe/oracly_universe_clock.dart';
import 'package:oracly_new/features/home/reference/home_daypart_preview.dart';
import 'package:oracly_new/features/home/theme/home_ritual_plates.dart';

void main() {
  test('four plates are distinct and share the greeting window', () {
    final plates = OraclyRitualTime.values.map(HomeRitualPlates.of).toSet();
    expect(plates, hasLength(4));
    const hours = <int, String>{
      4: 'İyi geceler',
      8: 'İyi sabahlar',
      14: 'İyi günler',
      19: 'İyi akşamlar',
    };
    for (final entry in hours.entries) {
      final time = OraclyRitualAtmosphere.fromHour(entry.key);
      expect(HomePersonalCopy.greeting(time: time), entry.value);
      expect(HomeRitualPlates.of(time), isNot(contains('home_hero_moon')));
    }
  });

  test('clock boundary, offset, and preview hour stay inside the window', () {
    final morning = DateTime(2026, 6, 15, 11, 59);
    expect(OraclyUniverseClock.nextBoundary(morning).hour, 12);
    final night = DateTime(2026, 6, 15, 23, 10);
    final next = OraclyUniverseClock.nextBoundary(night);
    expect(next.hour, 5);
    expect(next.day, 16);
    expect(
      OraclyUniverseClock.shouldRefresh(
        previous: OraclyRitualTime.morning,
        previousOffset: morning.timeZoneOffset,
        now: DateTime(2026, 6, 15, 12),
      ),
      isTrue,
    );
    final shifted = DateTime.utc(2026, 6, 15, 11);
    expect(
      OraclyUniverseClock.shouldRefresh(
        previous: OraclyRitualAtmosphere.fromHour(shifted.hour),
        previousOffset: const Duration(hours: 3),
        now: shifted,
      ),
      isTrue,
    );
    expect(HomeDaypartPreview.parse('noon'), OraclyRitualTime.afternoon);
    expect(HomeDaypartPreview.parse('nope'), isNull);
    final fixed = HomeDaypartPreview.momentFor(
      OraclyRitualTime.evening,
      DateTime(2026, 10, 17, 3),
    );
    expect(fixed.hour, 19);
    expect(
      OraclyRitualAtmosphere.fromHour(fixed.hour),
      OraclyRitualTime.evening,
    );
  });
}
