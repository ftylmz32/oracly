/// TAROT V1 — local persist, history reopen, gem hook.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/interpretation/formatters/interpretation_formatter.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';

const _savedMarkdown = '''
## Özet Mesaj
Bu bir aşk okuması. Üç kart tabloyu netleştirir.

## Kartlar
Kart: The Star (Düz)
Temel anlam: Umut ve yenilenme.
Bu açılımda mesajı: Geçmiş konumunda The Star.

Kart: The Moon (Ters)
Temel anlam: Belirsizlik görünür olur.
Bu açılımda mesajı: Şimdi konumunda The Moon.

## Aşk
Aşk: The Star (Düz). Bağda net konuş.

## Kariyer
Kariyer: The Moon (Ters). Küçük görünür adım.

## Maddi Durum
Maddi durum dengeli kalır.

## Genel Enerji
Genel enerji sakin ve odaklı.

## Sonuç
Net sonuç: Aşk tarafında The Star tabloyu görünür kılıyor.
''';

void main() {
  test('saved reading reopen keeps the same interpretation', () {
    final model = ReadingModel(
      id: 'hist_1',
      cardId: 17,
      cardName: 'Üç Kart · The Star',
      cardImageAsset: 'star.png',
      spreadType: 'Üç Kart',
      aiSummary: _savedMarkdown,
      createdAt: DateTime(2026, 8, 8),
      readingType: 'Aşk',
      intention: 'Aşk',
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
    final first = SavedReadingParser.toContent(entry: entry, model: model);
    final second = SavedReadingParser.toContent(entry: entry, model: model);

    expect(entry.readingType, 'Aşk');
    expect(entry.typeLabel, contains('Aşk'));
    expect(first.generalMeaning, contains('aşk okuması'));
    expect(first.love, contains('Aşk'));
    expect(first.career, contains('Kariyer'));
    expect(first.money, contains('Maddi'));
    expect(first.luckyEnergy, contains('enerji'));
    expect(first.closingMessage, contains('Net sonuç'));
    expect(first.cardReadings, contains('Kart: The Star (Düz)'));
    expect(first.cardReadings, contains('Ters'));
    expect(first.userQuestion, 'Aşk');
    expect(first.generalMeaning, second.generalMeaning);
    expect(first.love, second.love);
    expect(first.fullInterpretation, second.fullInterpretation);
    expect(
      first.fullInterpretation,
      contains('Bu bir aşk okuması. Üç kart tabloyu netleştirir.'),
    );
    expect(first.fullInterpretation, contains('Kart: The Star (Düz)'));
    expect(first.fullInterpretation, contains('Kart: The Moon (Ters)'));
    expect(
      first.fullInterpretation,
      contains('Net sonuç: Aşk tarafında The Star tabloyu görünür kılıyor.'),
    );
  });

  test('reading model persists type cards and orientation', () {
    final model = ReadingModel(
      id: 'p1',
      cardId: 17,
      cardName: 'The Star',
      cardImageAsset: 'star.png',
      spreadType: 'Üç Kart',
      aiSummary: '## Genel Yorum\nKayıtlı yorum.',
      createdAt: DateTime(2026, 8, 8, 15, 30),
      readingType: 'Kariyer',
      intention: 'Kariyer',
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
    final restored = ReadingModel.fromJson(model.toJson());
    expect(restored.readingType, 'Kariyer');
    expect(restored.cards, hasLength(2));
    expect(restored.cards[1].isReversed, isTrue);
    expect(restored.cards[0].positionLabel, 'Geçmiş');
  });

  test('markdown round-trip does not invent a new reading', () {
    const formatter = InterpretationFormatter();
    const raw = '''
## Genel Yorum
Kaydedilmiş genel yorum.

## Aşk
Kaydedilmiş aşk.

## Sonuç
Kaydedilmiş sonuç.
''';
    final first = formatter.parseRawResponse(
      rawText: raw,
      requestId: 'a',
      sessionId: 's',
    )!;
    final second = formatter.parseRawResponse(
      rawText: raw,
      requestId: 'a',
      sessionId: 's',
    )!;
    expect(first.summary, 'Kaydedilmiş genel yorum.');
    expect(first.love, second.love);
    expect(first.closingMessage, 'Kaydedilmiş sonuç.');
  });

  test('gem hook keeps the existing tarot cost', () {
    expect(TarotEconomy.hasCost, isTrue);
    expect(TarotEconomy.readingCost, 20);
  });
}
