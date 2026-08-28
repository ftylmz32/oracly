/// Tarot, astrology, Yıldızname, SoulMate interpretation quality.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/astrology/data/astrology_daily_copy.dart';
import 'package:oracly_new/features/insights/services/reflective_card_relation.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation.dart';
import 'package:oracly_new/features/star_map/data/star_map_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';

void main() {
  test('tarot cards interact instead of listing two definitions', () {
    const past = ReadingCardContext(
      cardId: 0,
      cardName: 'The Fool',
      positionIndex: 0,
      positionLabel: 'Geçmiş',
      positionKey: 'past',
      isReversed: false,
      uprightMeaning: 'Yeni başlangıçlar ve cesaret.',
      reversedMeaning: 'Dikkatsizlik.',
      keywords: ['başlangıç', 'hareket'],
    );
    const now = ReadingCardContext(
      cardId: 18,
      cardName: 'The Moon',
      positionIndex: 1,
      positionLabel: 'Şimdi',
      positionKey: 'present',
      isReversed: false,
      uprightMeaning: 'Belirsizlik ve sezgi.',
      reversedMeaning: 'Korku.',
      keywords: ['belirsiz', 'sis'],
    );
    final pair = ReflectiveCardRelation.pair(past, now);
    expect(pair, contains('Fool'));
    expect(pair, contains('Moon'));
    expect(pair, contains('birlikte'));
    final result = ReflectiveIntelligence.synthesize(
      context: ReadingContext(
        sessionId: 's',
        spreadType: TarotSpreadType.threeCard,
        spreadLabel: 'Üç Kart',
        deckId: 'rider',
        language: 'tr',
        readingDate: DateTime(2026, 8, 15),
        cards: [
          past,
          now,
          const ReadingCardContext(
            cardId: 1,
            cardName: 'The Magician',
            positionIndex: 2,
            positionLabel: 'Olası yön',
            positionKey: 'near',
            isReversed: false,
            uprightMeaning: 'İrade ve beceri.',
            reversedMeaning: 'Dağınık niyet.',
            keywords: ['irade'],
          ),
        ],
      ),
      requestId: 'q',
    );
    expect(result.health.toLowerCase(), contains('fool'));
    expect(result.health.toLowerCase(), contains('moon'));
    expect(result.luckyEnergy.toLowerCase(), contains('eğilim'));
    expect(FortuneVoice.claimsCertainty(result.health), isFalse);
    expect(result.luckyEnergy.toLowerCase(), isNot(contains('fırsat')));
  });

  test('astrology and yıldızname stay sun-sign specific and honest', () {
    OraclyL10n.bind('tr');
    final gemini = AstrologyDailyCopy.forId('gemini');
    expect(gemini.overall.first, contains('yarım kalmış bir konuşmanın'));
    expect(FortuneVoice.claimsCertainty(gemini.overall.first), isFalse);
    expect(gemini.love.toLowerCase(), contains('sohbet'));
    expect(gemini.overall.join().toLowerCase(), isNot(contains('öne çıkar')));
    expect(gemini.overall.join().toLowerCase(), isNot(contains('enerji')));
    final sky = StarMapCopy.skyMessage(0, sunLabel: 'İkizler');
    expect(sky.today, contains('İkizler'));
    expect(sky.today.toLowerCase(), isNot(contains('yansıma')));
    expect(sky.today.toLowerCase(), isNot(contains('ay burcu')));
    OraclyL10n.bind('en');
    final geminiEn = AstrologyDailyCopy.forId('gemini');
    expect(geminiEn.overall.first.toLowerCase(), contains('unfinished'));
    expect(geminiEn.overall.first, isNot(contains('iletişim ön plana')));
    expect(StarMapCopy.skyMessage(0, sunLabel: 'Gemini').today, contains('Gemini'));
    expect(StarMapCopy.skyMessage(0).today, isNot(contains('Bugünkü')));
    OraclyL10n.bind('ru');
    expect(AstrologyDailyCopy.forId('gemini').overall.first, contains('разговору'));
    expect(StarMapCopy.karmic(0).theme, isNot(contains('Söz ve')));
    OraclyL10n.bind('tr');
  });

  test('soulmate uses actual inputs and never claims arrival', () {
    final text = SoulMateInterpretation.forRequest(
      SoulMateDrawRequest(
        name: 'Ayşe',
        birthDate: DateTime(1994, 3, 12),
        intention: 'sakin bir bağ',
      ),
    );
    expect(text, contains('Ayşe'));
    expect(text.toLowerCase(), contains('sakin'));
    expect(text.toLowerCase(), isNot(contains('kesin')));
    expect(text.toLowerCase(), isNot(contains('hayatına girecek')));
    expect(text.toLowerCase(), isNot(contains('enerji')));
    expect(SoulMateCopy.honesty.toLowerCase(), contains('sembolik'));
    expect(SoulMateCopy.honesty.toLowerCase(), contains('gerçek bir kişi'));
    expect(SoulMateCopy.honesty.toLowerCase(), isNot(contains('kesin buluşma')));
  });
}
