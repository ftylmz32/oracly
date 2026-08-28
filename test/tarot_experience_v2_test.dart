/// TAROT V2 — interpretation-first reading, OR context, history, copy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_conversation_responder.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';
import 'package:oracly_new/core/personality/or_living_voice.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_position.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/interpretation/formatters/interpretation_formatter.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/core/domain/models/reading.dart';

ReadingCardContext _card({
  required int id,
  required String name,
  required int index,
  required String label,
  required bool reversed,
  required String upright,
  required String reversedMeaning,
}) {
  return ReadingCardContext(
    cardId: id,
    cardName: name,
    positionIndex: index,
    positionLabel: label,
    positionKey: label.toLowerCase(),
    isReversed: reversed,
    uprightMeaning: upright,
    reversedMeaning: reversedMeaning,
    keywords: const ['odak'],
  );
}

ReadingContext _ctx(String theme, {int cards = 3}) {
  final all = [
    _card(
      id: 0,
      name: 'The Fool',
      index: 0,
      label: 'Geçmiş',
      reversed: false,
      upright: 'Yeni bir başlangıç.',
      reversedMeaning: 'Tereddüt.',
    ),
    _card(
      id: 1,
      name: 'The Magician',
      index: 1,
      label: 'Şimdi',
      reversed: true,
      upright: 'Yaratıcı güç.',
      reversedMeaning: 'Dağınık niyet.',
    ),
    _card(
      id: 2,
      name: 'The High Priestess',
      index: 2,
      label: 'Olası yön',
      reversed: false,
      upright: 'İç ses.',
      reversedMeaning: 'Gizli kalmış bilgi.',
    ),
  ];
  return ReadingContext(
    sessionId: 'v2_$theme',
    spreadType: cards == 1 ? TarotSpreadType.single : TarotSpreadType.threeCard,
    spreadLabel: cards == 1 ? 'Tek Kart' : 'Üç Kart',
    deckId: 'rider-waite',
    language: 'tr',
    readingDate: DateTime(2026, 8, 9),
    readingTheme: theme,
    userQuestion: theme == 'love' ? 'Aşk hayatımda neye dikkat etmeliyim?' : null,
    cards: all.take(cards).toList(),
  );
}

void main() {
  test('loading and error copy match the spec', () {
    expect(
      TarotPolishCopy.interpreting,
      isIn(OrLivingVoice.thinkingPool(OrLivingSurface.tarot)),
    );
    expect(
      TarotPolishCopy.interpretFailed,
      'Yorum bu sefer tutmadı. Bir daha deneyelim.',
    );
    expect(TarotPolishCopy.retry, 'TEKRAR DENE');
  });

  test('three-card positions are past present near-term', () {
    final labels = SpreadService.positionsFor(TarotSpreadType.threeCard)
        .map((p) => p.labelTr)
        .toList();
    expect(labels, ['Geçmiş', 'Şimdi', 'Gelecek']);
  });

  test('interpretations change with intention', () {
    final love = ReflectiveIntelligence.synthesize(
      context: _ctx('love'),
      requestId: 'l',
    );
    final career = ReflectiveIntelligence.synthesize(
      context: _ctx('career'),
      requestId: 'c',
    );
    final daily = ReflectiveIntelligence.synthesize(
      context: _ctx('daily'),
      requestId: 'd',
    );
    final general = ReflectiveIntelligence.synthesize(
      context: _ctx('general'),
      requestId: 'g',
    );
    expect(love.love, isNotEmpty);
    expect(love.career, isEmpty);
    expect(career.career, isNotEmpty);
    expect(career.love, isEmpty);
    expect(daily.spiritualGuidance, isNotEmpty);
    expect(daily.love, isEmpty);
    expect(general.money, isNotEmpty);
    expect(general.love, isEmpty);
    expect(love.love, isNot(equals(career.career)));
    expect(love.love.toLowerCase(), contains('duygusal'));
    expect(career.career.toLowerCase(), contains('iş'));
    expect(daily.spiritualGuidance.toLowerCase(), contains('bugün'));
  });

  test('three-card synthesis connects cards without certainty', () {
    final result = ReflectiveIntelligence.synthesize(
      context: _ctx('general'),
      requestId: 's',
    );
    final text = result.luckyEnergy.toLowerCase();
    expect(text, contains('fool'));
    expect(text, contains('magician'));
    expect(text, contains('olası yön'));
    expect(text, contains('eğilim'));
    expect(
      text.contains('aynı masada') || text.contains('yan yana'),
      isTrue,
    );
    expect(text, isNot(contains('kesinlikle')));
    expect(text, isNot(contains('evren sana')));
    expect(result.warnings.split('\n'), hasLength(lessThanOrEqualTo(2)));
  });

  test('reversed cards are explained in the card block', () {
    final result = ReflectiveIntelligence.synthesize(
      context: _ctx('love'),
      requestId: 'r',
    );
    expect(result.health, contains('Ters'));
    expect(result.health, contains('Dağınık niyet'));
    expect(result.health.toLowerCase(), contains('aşk hayatımda'));
  });

  test('one-card reading still answers before asking', () {
    final result = ReflectiveIntelligence.synthesize(
      context: _ctx('daily', cards: 1),
      requestId: 'one',
    );
    expect(result.summary, isNotEmpty);
    expect(result.dailyFocus, isNotEmpty);
    expect(result.warnings, isNotEmpty);
    expect(result.warnings.contains('?'), isFalse);
    expect(result.warnings.toLowerCase(), contains('adım'));
    final markdown = const InterpretationFormatter().toMarkdown(result);
    expect(
      markdown.indexOf('Bugün İçin Mesaj'),
      lessThan(markdown.indexOf('Kendine Sor')),
    );
  });

  test('reveal subtitle shows position and orientation, not the reading', () {
    final upright = RevealCardData.fromDrawnCard(
      TarotDrawnCard(
        card: CardRevealSpread.forIndex(0).card,
        positionIndex: 0,
        isReversed: false,
        positionLabel: 'Şimdi',
      ),
    );
    final reversed = RevealCardData.fromDrawnCard(
      TarotDrawnCard(
        card: CardRevealSpread.forIndex(1).card,
        positionIndex: 1,
        isReversed: true,
        positionLabel: 'Geçmiş',
      ),
    );
    expect(upright.subtitle, contains('Şimdi'));
    expect(upright.subtitle, contains('Kartın Yönü: Düz'));
    expect(reversed.subtitle, contains('Geçmiş'));
    expect(reversed.subtitle, contains('Kartın Yönü: Ters'));
    expect(upright.subtitle, isNot(contains('Bu kart genel olarak')));
  });

  test('OR receives full tarot context and answers directly', () async {
    final session = ReadingSession(
      id: 'or_v2',
      deckId: 'rider-waite',
      spread: TarotSpreadType.threeCard,
      intention: const TarotIntention(
        text: 'Aşk hayatımda neye dikkat etmeliyim?',
        topic: 'love',
      ),
      shuffleSeed: 3,
      startedAt: DateTime(2026, 8, 9),
      drawnCards: [
        TarotDrawnCard(
          card: CardRevealSpread.forIndex(0).card,
          positionIndex: 0,
          isReversed: false,
          positionLabel: 'Geçmiş',
        ),
        TarotDrawnCard(
          card: CardRevealSpread.forIndex(1).card,
          positionIndex: 1,
          isReversed: true,
          positionLabel: 'Şimdi',
        ),
        TarotDrawnCard(
          card: CardRevealSpread.forIndex(2).card,
          positionIndex: 2,
          isReversed: false,
          positionLabel: 'Olası yön',
        ),
      ],
    );
    final content = AiReadingContent(
      cardName: 'Üç Kart Açılımı',
      tagline: 'Aşk',
      generalMeaning: 'Tema: bağ ve net konuşma.',
      love: 'Duygusal halde mesafe ve yakınlık birlikte duruyor.',
      career: '',
      money: '',
      spiritualGuidance: '',
      luckyEnergy:
          'Geçmişteki Fool ile şu anki Magician birlikte ritmi sadeleştiriyor.',
      dailyAdvice: 'Bugün tek net cümle söyle.',
      imageAsset: 'star.png',
      rarityColor: const Color(0xFF9B6DFF),
      fullInterpretation: '## Açılımın Teması\nTema: bağ ve net konuşma.',
      cardReadings: 'Kart: The Moon\nKartın Yönü: Ters\nTemel Anlam: belirsizlik.',
      drawnCards: session.drawnCards,
      readingTheme: 'love',
    );
    final ctx = OracleReadingContext.fromSession(
      session: session,
      content: content,
    );
    expect(ctx.userQuestion, contains('Aşk hayatımda'));
    expect(ctx.cardsSummary, contains('Ters'));
    expect(ctx.cardIds, hasLength(3));
    expect(ctx.fullInterpretation, isNull);
    final responder = OracleConversationResponder();
    final love = await responder.respond(
      context: ctx,
      userMessage: 'Bu açılımda aşk konusunda ne görüyorsun?',
    );
    final reversed = await responder.respond(
      context: ctx,
      userMessage: 'İkinci kart neden ters?',
    );
    final primary = await responder.respond(
      context: ctx,
      userMessage: 'Bu açılımda en önemli kart hangisi?',
    );
    final message = await responder.respond(
      context: ctx,
      userMessage: 'Benim için burada asıl mesaj ne?',
    );
    expect(love.toLowerCase(), contains('aşk'));
    expect(love, isNot(contains('Düşünmek için')));
    expect(reversed.toLowerCase(), contains('ters'));
    expect(primary.toLowerCase(), contains('omurga'));
    expect(message, isNotEmpty);
  });

  test('history reopen keeps the complete interpretation', () {
    const markdown = '''
## Açılımın Teması
Kartların bugün öne çıkardığı ana tema net konuşma.

## Kartların Mesajı
Kart: The Star
Kartın Yönü: Düz
Temel Anlam: Umut.

Kart: The Moon
Kartın Yönü: Ters
Temel Anlam: Belirsizlik.

## Açılımın Genel Yorumu
Geçmişteki Star ile şu anki Moon birlikte ritmi sadeleştiriyor.

## Aşk
Duygusal halde mesafe görünür olabilir.

## Bugün İçin Mesaj
Tek net cümle söyle.

## Kendine Sor
Bu bağda neyi netleştirmek isterdin?
''';
    final model = ReadingModel(
      id: 'hist_v2',
      cardId: 17,
      cardName: 'Üç Kart · The Star',
      cardImageAsset: 'star.png',
      spreadType: 'Üç Kart',
      aiSummary: markdown,
      createdAt: DateTime(2026, 8, 9, 10, 30),
      intention: 'Aşk hayatımda neye dikkat etmeliyim?',
      readingType: 'love',
      cards: const [
        ReadingCardSnapshot(
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'star.png',
          positionIndex: 0,
          positionLabel: 'Geçmiş',
        ),
        ReadingCardSnapshot(
          cardId: 18,
          cardName: 'The Moon',
          cardImageAsset: 'moon.png',
          positionIndex: 1,
          positionLabel: 'Şimdi',
          isReversed: true,
        ),
      ],
    );
    final entry = ReadingHistoryMapper.fromModel(model);
    final restored = SavedReadingParser.toContent(entry: entry, model: model);
    expect(restored.generalMeaning, contains('net konuşma'));
    expect(restored.luckyEnergy, contains('Star'));
    expect(restored.love, contains('Duygusal'));
    expect(restored.dailyAdvice, contains('Tek net cümle'));
    expect(restored.promptQuestion, contains('?'));
    expect(restored.cardReadings, contains('Ters'));
    expect(restored.readingTheme, 'love');
    expect(restored.userQuestion, contains('Aşk'));
  });

  test('gem cost stays unchanged', () {
    expect(TarotEconomy.readingCost, 20);
  });
}
