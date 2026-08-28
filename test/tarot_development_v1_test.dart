/// TAROT V1 — reading types, positions, card-driven results.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/insights/services/reflective_reading_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_position.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/presentation/epic031/tarot_epic031_spec.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';

ReadingSession _session(String topic, String label) {
  return ReadingSession(
    id: 'v1_$topic',
    deckId: 'rider-waite',
    spread: TarotSpreadType.threeCard,
    intention: TarotIntention(text: label, topic: topic),
    shuffleSeed: 42,
    startedAt: DateTime(2026, 8, 8),
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
        positionLabel: 'Gelecek',
      ),
    ],
  );
}

ReadingContext _theme(String theme) {
  ReadingCardContext card({
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

  return ReadingContext(
    sessionId: 'theme_$theme',
    spreadType: TarotSpreadType.threeCard,
    spreadLabel: 'Üç Kart',
    deckId: 'rider-waite',
    language: 'tr',
    readingDate: DateTime(2026, 8, 8),
    readingTheme: theme,
    cards: [
      card(
        id: 0,
        name: 'The Fool',
        index: 0,
        label: 'Geçmiş',
        reversed: false,
        upright: 'Yeni bir başlangıç.',
        reversedMeaning: 'Tereddüt.',
      ),
      card(
        id: 1,
        name: 'The Magician',
        index: 1,
        label: 'Şimdi',
        reversed: true,
        upright: 'Yaratıcı güç.',
        reversedMeaning: 'Dağınık niyet.',
      ),
      card(
        id: 2,
        name: 'The High Priestess',
        index: 2,
        label: 'Olası yön',
        reversed: false,
        upright: 'İç ses.',
        reversedMeaning: 'Gizli kalmış bilgi.',
      ),
    ],
  );
}

void main() {
  test('home categories map to interpretation topics', () {
    expect(TarotEpic031Category.daily.topicId, 'daily');
    expect(TarotEpic031Category.love.topicId, 'love');
    expect(TarotEpic031Category.career.topicId, 'career');
    expect(TarotEpic031Category.general.topicId, 'general');
  });

  test('three-card positions are Geçmiş Şimdi Gelecek', () {
    final labels = SpreadService.positionsFor(TarotSpreadType.threeCard)
        .map((p) => p.labelTr)
        .toList();
    expect(labels, ['Geçmiş', 'Şimdi', 'Gelecek']);
  });

  test('reading type changes interpretation context', () {
    expect(ReflectiveReadingCopy.conclusion(_theme('love')), contains('Aşk'));
    expect(
      ReflectiveReadingCopy.conclusion(_theme('career')),
      contains('Kariyer'),
    );
    expect(ReflectiveReadingCopy.conclusion(_theme('daily')), contains('Bugün'));
    expect(
      ReflectiveReadingCopy.conclusion(_theme('general')),
      contains('Genel bakışta'),
    );
    expect(ReflectiveReadingCopy.questions(_theme('love')), isNotEmpty);
    expect(
      ReflectiveReadingCopy.questions(_theme('career')),
      isNot(ReflectiveReadingCopy.questions(_theme('love'))),
    );
    expect(ReflectiveReadingCopy.general(_theme('love')), contains('The Fool'));
  });

  test('daily love career general stay card-driven', () async {
    final service = TarotInterpretationService();
    const cases = [
      ('daily', 'Günlük Fal'),
      ('love', 'Aşk'),
      ('career', 'Kariyer'),
      ('general', 'Genel'),
    ];
    for (final entry in cases) {
      final content = await service.generateContent(
        _session(entry.$1, entry.$2),
      );
      expect(content.readingTheme, entry.$1);
      expect(content.generalMeaning, isNotEmpty);
      expect(content.cardReadings, contains('Geçmiş'));
      expect(content.cardReadings, contains('Şimdi'));
      expect(content.cardReadings, contains('Gelecek'));
      expect(content.cardReadings, contains('Ters'));
      expect(content.dailyAdvice, isNotEmpty);
      expect(content.promptQuestion, isNotEmpty);
      expect(content.promptQuestion.toLowerCase(), isNot(contains('mutlaka')));
      if (entry.$1 == 'love') {
        expect(content.love, isNotEmpty);
        expect(content.career, isEmpty);
      } else if (entry.$1 == 'career') {
        expect(content.career, isNotEmpty);
        expect(content.love, isEmpty);
      } else if (entry.$1 == 'daily') {
        expect(content.spiritualGuidance, isNotEmpty);
        expect(content.love, isEmpty);
      } else {
        expect(content.money, isNotEmpty);
        expect(content.love, isEmpty);
      }
      expect(content.drawnCards, hasLength(3));
      expect(content.drawnCards[1].isReversed, isTrue);
    }
  });
}
