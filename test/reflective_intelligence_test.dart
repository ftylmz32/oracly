import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/models/ritual_journal_metadata.dart';
import 'package:oracly_new/features/insights/models/journey_personalization_hints.dart';
import 'package:oracly_new/features/insights/services/journey_personalization_builder.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';

void main() {
  group('ReflectiveIntelligence', () {
    test('synthesis avoids fortune-teller tone', () {
      final context = _sampleContext();
      final result = ReflectiveIntelligence.synthesize(
        context: context,
        requestId: 'req_1',
      );

      expect(
        ReflectiveIntelligence.containsForbiddenTone(result.summary),
        isFalse,
      );
      expect(
        ReflectiveIntelligence.containsForbiddenTone(result.closingMessage),
        isFalse,
      );
      expect(result.summary.toLowerCase(), isNot(contains('evren seninle')));
      expect(result.closingMessage.toLowerCase(), contains('yankı'));
    });

    test('spiritual guidance uses reflection questions', () {
      final result = ReflectiveIntelligence.synthesize(
        context: _sampleContext(),
        requestId: 'req_2',
      );

      expect(result.spiritualGuidance, contains('•'));
      expect(result.spiritualGuidance.toLowerCase(), contains('sor'));
    });

    test('guard softens certainty language', () {
      const harsh = 'Kesinlikle mutlaka evren seninle konuşuyor.';
      final softened = ReflectiveIntelligence.soften(harsh);

      expect(softened.toLowerCase(), isNot(contains('kesinlikle')));
      expect(softened.toLowerCase(), isNot(contains('mutlaka')));
      expect(softened.toLowerCase(), isNot(contains('evren seninle konuşuyor')));
    });
  });

  group('JourneyPersonalizationBuilder', () {
    test('does not invent patterns with insufficient history', () {
      final hints = JourneyPersonalizationBuilder.fromHistory([
        _reading(id: 'r0', cardName: 'The Fool', summary: 'test'),
      ]);

      expect(hints.recurringThemeLabels, isEmpty);
      expect(hints.observationalPreface(), isNull);
    });

    test('cites recurring themes only when observable', () {
      final readings = List.generate(
        4,
        (i) => _reading(
          id: 'r$i',
          cardName: 'The Magician',
          summary: 'aşk ve bağ teması',
          intention: 'ilişkim',
        ),
      );

      final hints = JourneyPersonalizationBuilder.fromHistory(readings);
      final preface = hints.observationalPreface();

      expect(hints.recurringThemeLabels, isNotEmpty);
      expect(preface, isNotNull);
      expect(preface!.toLowerCase(), contains('aşk'));
    });
  });

  group('JourneyPersonalizationHints', () {
    test('isEmpty when no observable data', () {
      const hints = JourneyPersonalizationHints();
      expect(hints.isEmpty, isTrue);
    });
  });
}

ReadingContext _sampleContext() {
  return ReadingContext(
    sessionId: 'session_test',
    spreadType: TarotSpreadType.threeCard,
    spreadLabel: 'Üç Kart',
    deckId: 'rider-waite',
    language: 'tr',
    readingDate: DateTime(2026, 8, 2),
    userQuestion: 'Genel rehberlik',
    cards: const [
      ReadingCardContext(
        cardId: 0,
        cardName: 'The Fool',
        positionIndex: 0,
        positionLabel: 'Geçmiş',
        positionKey: 'past',
        isReversed: false,
        uprightMeaning: 'Yeni başlangıçlar ve cesaret.',
        reversedMeaning: 'Dikkatsizlik.',
        keywords: ['başlangıç', 'cesaret', 'özgürlük'],
        element: 'Hava',
      ),
      ReadingCardContext(
        cardId: 1,
        cardName: 'The Magician',
        positionIndex: 1,
        positionLabel: 'Şimdi',
        positionKey: 'present',
        isReversed: true,
        uprightMeaning: 'Odak ve beceri.',
        reversedMeaning: 'Dağınıklık ve belirsizlik.',
        keywords: ['odak', 'beceri'],
        element: 'Ateş',
      ),
      ReadingCardContext(
        cardId: 2,
        cardName: 'The World',
        positionIndex: 2,
        positionLabel: 'Gelecek',
        positionKey: 'future',
        isReversed: false,
        uprightMeaning: 'Tamamlanma ve bütünlük.',
        reversedMeaning: 'Eksik kapanış.',
        keywords: ['tamamlanma', 'bütünlük'],
        element: 'Toprak',
      ),
    ],
  );
}

ReadingModel _reading({
  String id = 'r0',
  String cardName = 'The Star',
  String summary = '',
  String? intention,
}) {
  return ReadingModel(
    id: id,
    cardId: 17,
    cardName: cardName,
    cardImageAsset: 'assets/test.png',
    spreadType: 'Tek Kart',
    aiSummary: summary,
    createdAt: DateTime(2026, 7, id.hashCode % 28 + 1),
    intention: intention,
    journal: const RitualJournalMetadata(
      tags: ['insight:love'],
    ),
  );
}
