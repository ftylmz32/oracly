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
}
