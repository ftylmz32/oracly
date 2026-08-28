import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/star_map/services/star_map_reading_service.dart';

void main() {
  test('daily yıldızname reading is answer-first', () {
    final day = DateTime(2026, 8, 8);
    final reading = StarMapReadingService.build(now: day);

    expect(reading.overview.dominantEnergy.trim().isNotEmpty, isTrue);
    expect(reading.overview.mainMessage.trim().isNotEmpty, isTrue);
    expect(reading.overview.mainMessage.contains('?'), isFalse);
    expect(reading.skyMessage.today.trim().isNotEmpty, isTrue);
    expect(reading.skyMessage.advice.trim().isNotEmpty, isTrue);
    expect(reading.karmic.theme.trim().isNotEmpty, isTrue);
    expect(reading.karmic.takeaway.contains('?'), isFalse);
    expect(reading.karmic.promptQuestion.contains('?'), isTrue);
    expect(reading.planets.length, greaterThanOrEqualTo(5));
    expect(reading.planets.first.nameTr, 'Güneş');
    expect(reading.overview.whatItSays, StarMapPolishCopy.whatItIs);
    expect(reading.isPersonalized, isFalse);
    expect(
      reading.planets.first.explanation.toLowerCase(),
      isNot(contains('gökyüzünde')),
    );
  });

  test('same day is stable; sun sign personalizes overview', () {
    final day = DateTime(2026, 8, 8);
    final a = StarMapReadingService.build(now: day);
    final b = StarMapReadingService.build(now: day);
    final personal = StarMapReadingService.build(
      now: day,
      sunSign: ZodiacSignId.aries,
    );

    expect(a.overview.mainMessage, b.overview.mainMessage);
    expect(a.karmic.theme, b.karmic.theme);
    expect(personal.overview.whatItSays, contains('Koç'));
    expect(personal.overview.mainMessage, contains('Koç'));
    expect(personal.isPersonalized, isTrue);
    expect(a.isPersonalized, isFalse);
  });
}
