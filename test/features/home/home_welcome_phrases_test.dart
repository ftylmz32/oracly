import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/home/copy/home_welcome_phrases.dart';

void main() {
  test('HomeWelcomePhrases rotates daily without immediate repeat', () {
    final day = DateTime(2026, 8, 7);
    final nextDay = DateTime(2026, 8, 8);

    final today = HomeWelcomePhrases.forDay(day: day, salt: 'Fatih');
    final tomorrow = HomeWelcomePhrases.forDay(day: nextDay, salt: 'Fatih');

    expect(today, isNotEmpty);
    expect(HomeWelcomePhrases.phrases, contains(today));
    expect(tomorrow, isNot(equals(today)));
  });

  test('HomeWelcomePhrases varies by user salt on same day', () {
    final day = DateTime(2026, 8, 7);

    final a = HomeWelcomePhrases.forDay(day: day, salt: 'Fatih');
    final b = HomeWelcomePhrases.forDay(day: day, salt: 'Ayşe');

    expect(a, isNotEmpty);
    expect(b, isNotEmpty);
  });
}
