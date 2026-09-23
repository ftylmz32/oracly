/// Phase 5D.1 — localized history search for machine-id spreadType rows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/insights/services/personal_journey_service.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_data.dart';

ReadingHistoryEntry _entry({
  required String id,
  required String spreadType,
  String cardName = 'The Star',
  String aiSummary = 'Calm reflection summary.',
  String? personalNote,
  String? readingType,
}) {
  return ReadingHistoryEntry(
    id: id,
    date: DateTime(2026, 9, 22),
    spreadType: spreadType,
    filter: HistorySpreadFilter.all,
    cardName: cardName,
    cardImageAsset: 'star.png',
    aiSummary: aiSummary,
    moodIcon: Icons.auto_awesome,
    cardIndex: 0,
    heroTag: 'h_$id',
    personalNote: personalNote,
    readingType: readingType,
  );
}

void main() {
  const journey = PersonalJourneyService();

  tearDown(() => OraclyL10n.bind(AppLocale.tr));

  group('PersonalJourneyService localized spread search', () {
    test('threeCard machine-id matches TR/EN/RU titles and raw id', () {
      final entries = [_entry(id: 't3', spreadType: 'threeCard')];

      OraclyL10n.bind(AppLocale.tr);
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'Üç Kart'),
        hasLength(1),
      );
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'threeCard'),
        hasLength(1),
      );

      OraclyL10n.bind(AppLocale.en);
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'Three Cards'),
        hasLength(1),
      );

      OraclyL10n.bind(AppLocale.ru);
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'Три карты'),
        hasLength(1),
      );
    });

    test('fiveCard machine-id matches TR/EN titles', () {
      final entries = [_entry(id: 't5', spreadType: 'fiveCard')];

      OraclyL10n.bind(AppLocale.tr);
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'Derin Açılım'),
        hasLength(1),
      );

      OraclyL10n.bind(AppLocale.en);
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'Deep Spread'),
        hasLength(1),
      );
    });

    test('crossroads machine-id matches TR/EN/RU titles', () {
      final entries = [_entry(id: 'cr', spreadType: 'crossroads')];

      OraclyL10n.bind(AppLocale.tr);
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'Yol Ayrımı'),
        hasLength(1),
      );

      OraclyL10n.bind(AppLocale.en);
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'Crossroads'),
        hasLength(1),
      );

      OraclyL10n.bind(AppLocale.ru);
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'Перекрёсток'),
        hasLength(1),
      );
    });

    test('legacy localized title remains searchable', () {
      final entries = [_entry(id: 'leg', spreadType: 'Üç Kart')];
      OraclyL10n.bind(AppLocale.tr);
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'Üç Kart'),
        hasLength(1),
      );
    });

    test('card / note / summary search unchanged', () {
      final entries = [
        _entry(
          id: 'fields',
          spreadType: 'threeCard',
          cardName: 'The Moon',
          aiSummary: 'Quiet moonlight reflection.',
          personalNote: 'My private journal note.',
        ),
      ];
      OraclyL10n.bind(AppLocale.en);
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'Moon'),
        hasLength(1),
      );
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'journal note'),
        hasLength(1),
      );
      expect(
        journey.filterEntries(entries, HistorySpreadFilter.all, 'moonlight'),
        hasLength(1),
      );
    });
  });

  group('fallback search implementations stay consistent', () {
    test('ReadingHistoryMapper.filterEntries matches localized titles', () {
      final entries = [_entry(id: 'm', spreadType: 'threeCard')];
      OraclyL10n.bind(AppLocale.tr);
      // ignore: deprecated_member_use_from_same_package
      expect(
        ReadingHistoryMapper.filterEntries(
          entries,
          HistorySpreadFilter.all,
          'Üç Kart',
        ),
        hasLength(1),
      );
    });

    test('ReadingHistoryCatalogue.filterBy matches localized titles', () {
      OraclyL10n.bind(AppLocale.tr);
      final matched = ReadingHistoryCatalogue.filterBy(
        HistorySpreadFilter.all,
        'Üç Kart',
      );
      // Catalogue samples use legacy localized titles; ensure query still works.
      expect(matched, isNotEmpty);
    });
  });
}
