import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/astrology/services/astrology_daily_reading_service.dart';
import 'package:oracly_new/features/content/astrology/data/astrology_content_catalogue.dart';

void main() {
  test('daily reading is sign-specific and answer-first', () {
    final aries = AstrologyContentCatalogue.signById('aries')!;
    final taurus = AstrologyContentCatalogue.signById('taurus')!;
    final day = DateTime(2026, 8, 8);

    final ariesReading = AstrologyDailyReadingService.build(aries, now: day);
    final taurusReading = AstrologyDailyReadingService.build(taurus, now: day);

    expect(ariesReading.overall.toLowerCase(), contains('koç'));
    expect(taurusReading.overall.toLowerCase(), contains('boğa'));
    expect(ariesReading.overall, isNot(equals(taurusReading.overall)));
    expect(ariesReading.love.trim().isEmpty, isTrue);
    expect(ariesReading.career.trim().isEmpty, isTrue);
    expect(ariesReading.money.trim().isEmpty, isTrue);
    expect(ariesReading.advice.trim().isNotEmpty, isTrue);
    expect(ariesReading.energy.trim().isNotEmpty, isTrue);
    expect(ariesReading.emotion.trim().isNotEmpty, isTrue);
    expect(ariesReading.opportunity.trim().isNotEmpty, isTrue);
    expect(ariesReading.caution.trim().isNotEmpty, isTrue);
    expect(ariesReading.personality.toLowerCase(), contains('koç'));
    expect(ariesReading.personality.toLowerCase(), contains('ritmine'));
    expect(ariesReading.overall.toLowerCase(), startsWith('koç'));
    expect(ariesReading.overall.toLowerCase(), isNot(contains('ön plana')));
    expect(ariesReading.advice.contains('?'), isFalse);
    expect(ariesReading.overall.contains('%'), isFalse);
    expect(ariesReading.love.contains('%'), isFalse);
    expect(ariesReading.career.contains('%'), isFalse);
    expect(ariesReading.energy.contains('%'), isFalse);
  });

  test('same sign and day produce stable catalogue copy', () {
    final cancer = AstrologyContentCatalogue.signById('cancer')!;
    final day = DateTime(2026, 8, 8);
    final a = AstrologyDailyReadingService.build(cancer, now: day);
    final b = AstrologyDailyReadingService.build(cancer, now: day);

    expect(a.overall, b.overall);
    expect(a.love, b.love);
    expect(a.career, b.career);
    expect(a.energy, b.energy);
  });

  test('twelve signs vary by day without repeating complete lanes', () {
    final signs = AstrologyContentCatalogue.signs;
    final sameDay = <String>{};

    for (final sign in signs) {
      final daily = <String>{};
      for (var offset = 0; offset < 6; offset++) {
        final reading = AstrologyDailyReadingService.build(
          sign,
          now: DateTime(2026, 10, 13 + offset),
        );
        daily.add(reading.overall);

        expect(reading.love, isEmpty);
        expect(reading.career, isEmpty);
        expect(reading.money, isEmpty);
        expect(reading.overall, isNot(contains(reading.emotion)));
        expect(reading.overall, isNot(contains(reading.caution)));

        final lanes = [
          reading.energy,
          reading.emotion,
          reading.advice,
          reading.opportunity,
          reading.caution,
        ];
        expect(lanes.toSet(), hasLength(lanes.length));
      }
      expect(daily.length, greaterThanOrEqualTo(3), reason: sign.id);
      sameDay.add(
        AstrologyDailyReadingService.build(
          sign,
          now: DateTime(2026, 10, 13),
        ).overall,
      );
    }

    expect(signs, hasLength(12));
    expect(sameDay, hasLength(12));
  });
}
