/// Phase 5D.1 — SavedReadingParser never renders raw spread machine ids.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_data.dart';

ReadingHistoryEntry _entry({
  required String spreadType,
  String summary = 'Stored reflection body.',
  String? readingType,
}) {
  return ReadingHistoryEntry(
    id: 'e1',
    date: DateTime(2026, 9, 22),
    spreadType: spreadType,
    filter: HistorySpreadFilter.three,
    cardName: 'The Star',
    cardImageAsset: 'star.png',
    aiSummary: summary,
    moodIcon: Icons.auto_awesome,
    cardIndex: 0,
    heroTag: 'h1',
    readingType: readingType,
  );
}

void main() {
  tearDown(() => OraclyL10n.bind(AppLocale.tr));

  group('fallback path (unparsed markdown)', () {
    test('threeCard TR — localized label, no raw machine id', () {
      OraclyL10n.bind(AppLocale.tr);
      final content = SavedReadingParser.toContent(
        entry: _entry(spreadType: 'threeCard'),
      );
      expect(content.spreadLabel, 'Üç Kart');
      expect(content.tagline, isNot('threeCard'));
      expect(content.tagline, 'Üç Kart');
      expect(content.readingTheme, isNot('threeCard'));
      expect(content.readingTheme, 'Üç Kart');
      expect(content.fullInterpretation, 'Stored reflection body.');
    });

    test('threeCard EN — localized label', () {
      OraclyL10n.bind(AppLocale.en);
      final content = SavedReadingParser.toContent(
        entry: _entry(spreadType: 'threeCard'),
      );
      expect(content.spreadLabel, 'Three Cards');
      expect(content.tagline, isNot('threeCard'));
      expect(content.tagline, 'Three Cards');
    });

    test('threeCard RU — localized label', () {
      OraclyL10n.bind(AppLocale.ru);
      final content = SavedReadingParser.toContent(
        entry: _entry(spreadType: 'threeCard'),
      );
      expect(content.spreadLabel, 'Три карты');
      expect(content.tagline, isNot('threeCard'));
    });

    test('crossroads TR — Yol Ayrımı, never raw crossroads', () {
      OraclyL10n.bind(AppLocale.tr);
      final content = SavedReadingParser.toContent(
        entry: _entry(spreadType: 'crossroads'),
      );
      expect(content.spreadLabel, 'Yol Ayrımı');
      expect(content.tagline, isNot('crossroads'));
      expect(content.tagline, 'Yol Ayrımı');
    });

    test('real readingType preserved over spread label', () {
      OraclyL10n.bind(AppLocale.tr);
      final content = SavedReadingParser.toContent(
        entry: _entry(spreadType: 'threeCard'),
        model: ReadingModel(
          id: 'm1',
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'star.png',
          spreadType: 'threeCard',
          readingType: 'career',
          aiSummary: 'Stored reflection body.',
          createdAt: DateTime(2026, 9, 22),
        ),
      );
      expect(content.spreadLabel, 'Üç Kart');
      expect(content.tagline, 'career');
      expect(content.readingTheme, 'career');
      expect(content.tagline, isNot('threeCard'));
    });

    test('legacy localized title still displays', () {
      OraclyL10n.bind(AppLocale.tr);
      final content = SavedReadingParser.toContent(
        entry: _entry(spreadType: 'Üç Kart'),
      );
      expect(content.spreadLabel, 'Üç Kart');
      expect(content.tagline, 'Üç Kart');
    });
  });

  group('parsed formatter path', () {
    const parsedMarkdown = '''
## Özet
Kaydedilmiş özet.

## Aşk
Sevgi yansıması.

## Kariyer
İş yansıması.
''';

    test('threeCard EN parsed — no raw machine id in tagline/theme', () {
      OraclyL10n.bind(AppLocale.en);
      final content = SavedReadingParser.toContent(
        entry: _entry(spreadType: 'threeCard', summary: parsedMarkdown),
      );
      expect(content.spreadLabel, 'Three Cards');
      expect(content.tagline, isNot('threeCard'));
      expect(content.readingTheme, isNot('threeCard'));
      expect(content.generalMeaning, contains('Kaydedilmiş'));
    });

    test('crossroads TR parsed — Yol Ayrımı', () {
      OraclyL10n.bind(AppLocale.tr);
      final content = SavedReadingParser.toContent(
        entry: _entry(spreadType: 'crossroads', summary: parsedMarkdown),
      );
      expect(content.spreadLabel, 'Yol Ayrımı');
      expect(content.tagline, isNot('crossroads'));
    });
  });
}
