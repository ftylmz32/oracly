import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';

void main() {
  test('generateContent returns non-empty interpretation sections', () async {
    final session = ReadingSession(
      id: 'test_session',
      deckId: 'rider-waite',
      spread: TarotSpreadType.threeCard,
      intention: const TarotIntention(text: 'Genel rehberlik'),
      shuffleSeed: 42,
      startedAt: DateTime.now(),
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

    final service = TarotInterpretationService();
    final content = await service.generateContent(session);

    expect(content.generalMeaning.trim().isNotEmpty, isTrue);
    expect(content.money.trim().isNotEmpty, isTrue);
    expect(content.love.trim().isEmpty, isTrue);
    expect(content.cardName, isNotEmpty);
    expect(
      content.generalMeaning.toLowerCase(),
      isNot(contains('evren seninle')),
    );
    expect(
      content.generalMeaning.toLowerCase(),
      isNot(contains('sana ne hatırlatıyor')),
    );
    expect(content.dailyAdvice.trim().isNotEmpty, isTrue);
    expect(content.cardReadings, contains('Geçmiş'));
    expect(content.cardReadings, contains('Ters'));
    final lucky = content.luckyEnergy.toLowerCase();
    expect(lucky.trim().isNotEmpty, isTrue);
    expect(
      lucky,
      anyOf(contains('sembolik'), contains('eğilim'), contains('yön')),
    );
    expect(lucky, isNot(contains('kesinlikle')));
    expect(lucky, isNot(contains('mutlaka olacak')));
    expect(content.promptQuestion, contains('?'));
    expect(content.isAiInterpretation, isFalse);
  });
}
