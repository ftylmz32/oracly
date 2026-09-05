import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/insights/models/journey_personalization_hints.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';

const _card = ReadingCardContext(
  cardId: 2,
  cardName: 'The High Priestess',
  positionIndex: 0,
  positionLabel: 'Şimdi',
  positionKey: 'present',
  isReversed: false,
  uprightMeaning: 'Sessiz gözlem.',
  reversedMeaning: 'İçe kapanma.',
  keywords: ['gözlem'],
);

ReadingContext _context(JourneyPersonalizationHints hints) {
  return ReadingContext(
    sessionId: 'same-session',
    spreadType: TarotSpreadType.single,
    spreadLabel: 'Tek Kart',
    deckId: 'classic',
    language: 'tr',
    readingDate: DateTime(2026, 9, 5),
    userQuestion: 'Bu kararı nasıl ele almalıyım?',
    readingTheme: 'career',
    shuffleSeed: 42,
    cards: const [_card],
    journeyHints: hints,
  );
}

void main() {
  test('same reading count with different continuity does not share cache', () {
    const career = JourneyPersonalizationHints(
      priorReadingCount: 4,
      recurringThemeLabels: ['career'],
      recentCardNames: ['The Chariot'],
    );
    const relationship = JourneyPersonalizationHints(
      priorReadingCount: 4,
      recurringThemeLabels: ['relationship'],
      recentCardNames: ['The Lovers'],
    );

    expect(career.cacheToken, isNot(equals(relationship.cacheToken)));
    expect(_context(career).cacheKey, isNot(equals(_context(relationship).cacheKey)));
  });

  test('revisit evidence changes tarot cache identity', () {
    const base = JourneyPersonalizationHints(
      priorReadingCount: 3,
      recurringThemeLabels: ['career'],
    );
    final revisit = base.withRevisit(
      priorExcerpt: 'Geçen okumada beklemek ile hareket etmek arasında kalmıştın.',
      instruction: 'Önceki açılımla ihtiyatlı biçimde karşılaştır.',
    );

    expect(base.cacheToken, isNot(equals(revisit.cacheToken)));
    expect(_context(base).cacheKey, isNot(equals(_context(revisit).cacheKey)));
  });

  test('identical evidence produces stable cache identity', () {
    const a = JourneyPersonalizationHints(
      priorReadingCount: 2,
      hasPriorNotes: true,
      recurringThemeLabels: ['career', 'change'],
      recentCardNames: ['The Fool'],
      priorOpenings: ['burada biraz duracağım'],
    );
    const b = JourneyPersonalizationHints(
      priorReadingCount: 2,
      hasPriorNotes: true,
      recurringThemeLabels: ['career', 'change'],
      recentCardNames: ['The Fool'],
      priorOpenings: ['burada biraz duracağım'],
    );

    expect(a.cacheToken, equals(b.cacheToken));
    expect(_context(a).cacheKey, equals(_context(b).cacheKey));
  });
}
