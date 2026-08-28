/// P1 — real interpretation output quality: warmth, clarity, no forced quiz.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading/human_reader.dart';
import 'package:oracly_new/features/astrology/services/astrology_daily_reading_service.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_composer.dart';
import 'package:oracly_new/features/companion/data/companion_answer_copy.dart';
import 'package:oracly_new/features/content/astrology/data/astrology_content_catalogue.dart';
import 'package:oracly_new/features/daily_message/data/daily_message_catalogue.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reading_presentation.dart';
import 'package:oracly_new/features/star_map/services/star_map_reading_service.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('coffee readings avoid quiz tone and equation dumps', () {
    const cups = [
      ['kuş', 'yol'],
      ['kalp', 'yüzük'],
      ['dağ', 'anahtar'],
      ['kuş'],
      ['mektup', 'yol'],
    ];
    for (var i = 0; i < cups.length; i++) {
      final text = CoffeeFortuneComposer.compose(
        CoffeeReading(
          id: 'q-$i',
          createdAt: DateTime(2026, 8, 24),
          overall: '',
          love: '',
          career: '',
          money: '',
          nearFuture: '',
          takeaway: '',
          visualObservation: 'Ağızda ${cups[i].join(' ve ')} duruyor.',
          symbols: [
            for (final name in cups[i])
              CoffeeSymbol(name: name, meaning: '', interpretation: ''),
          ],
        ),
      ).overall;
      expect(text.contains('?'), isFalse, reason: text);
      expect(text.contains('='), isFalse, reason: text);
      expect(text.toLowerCase(), isNot(contains('kendine sorman')));
      expect(HumanReader.looksGeneric(text), isFalse, reason: text);
      expect(FortuneVoice.looksRobotic(text), isFalse, reason: text);
    }
  });

  test('astrology overall is sky-grounded without quiz or new-age filler', () {
    final signs = AstrologyContentCatalogue.signs.take(6).toList();
    for (var i = 0; i < 8; i++) {
      final text = AstrologyDailyReadingService.build(
        signs[i % signs.length],
        now: DateTime(2026, 8, 10 + i),
      ).overall;
      expect(text.contains('?'), isFalse, reason: text);
      expect(text.toLowerCase(), contains('gökyüz'));
      expect(text.toLowerCase(), isNot(contains('bolluk bilinci')));
      expect(text.toLowerCase(), isNot(contains('seçilir duruyor')));
      expect(HumanReader.looksGeneric(text), isFalse, reason: text);
    }
  });

  test('yildizname soft chapters avoid meta invention voice', () {
    for (var i = 0; i < 6; i++) {
      final reading = StarMapReadingService.build(
        now: DateTime(2026, 8, 10 + i),
        sunSign: i.isEven ? ZodiacSignId.aries : ZodiacSignId.leo,
      );
      final pack = [
        StarMapReadingPresentation.todayBody(reading),
        StarMapReadingPresentation.innerBody(reading),
        StarMapReadingPresentation.journeyBody(reading),
        StarMapReadingPresentation.thresholdBody(reading),
        StarMapReadingPresentation.questionBody(reading),
      ].join(' ');
      expect(pack.contains('?'), isFalse, reason: pack);
      expect(pack.toLowerCase(), isNot(contains('uydurmuyorum')));
      expect(pack.toLowerCase(), isNot(contains('uydurma bir')));
      expect(pack.toLowerCase(), isNot(contains('sana bıraktığı soru')));
    }
  });

  test('daily empty pool stays concrete without prophecy meta', () {
    final lines = DailyMessageCatalogue.dateAware(DateTime(2026, 8, 24));
    expect(lines, hasLength(16));
    for (final line in lines) {
      expect(line.contains('?'), isFalse, reason: line);
      expect(line.toLowerCase(), isNot(contains('kehanet')));
      expect(line.toLowerCase(), isNot(contains('hediye')));
    }
  });

  test('OR answer copy is knowledge-first, not a quiz loop', () {
    for (final text in [
      CompanionAnswerCopy.tarot,
      CompanionAnswerCopy.coffee,
      CompanionAnswerCopy.astrology,
      CompanionAnswerCopy.dream,
      CompanionAnswerCopy.general,
    ]) {
      expect(text.contains('?'), isFalse, reason: text);
      expect('birlikte okuruz'.allMatches(text.toLowerCase()).length, lessThan(2));
    }
  });
}
