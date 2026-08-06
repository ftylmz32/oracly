/// EPIC-012 — Personal journey service tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/models/ritual_journal_metadata.dart';
import 'package:oracly_new/features/insights/services/personal_journey_service.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_timeline.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_data.dart';

void main() {
  const service = PersonalJourneyService();

  group('PersonalJourneyService', () {
    test('compose tracks memories not gamified stats', () {
      final readings = [
        ReadingModel(
          id: 'r1',
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'star.png',
          spreadType: 'Tek Kart',
          aiSummary: 'Umut ve rehberlik.',
          createdAt: DateTime(2026, 7, 2),
          journal: const RitualJournalMetadata(
            personalNote: 'Sakin bir gün.',
            isFavorite: true,
          ),
        ),
        ReadingModel(
          id: 'r2',
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'star.png',
          spreadType: 'Tek Kart',
          aiSummary: 'Umut tekrar belirdi.',
          createdAt: DateTime(2026, 8, 4),
        ),
      ];

      final snapshot = service.compose(readings);

      expect(snapshot.totalReadings, 2);
      expect(snapshot.notesWritten, 1);
      expect(snapshot.favoritedMemories, 1);
      expect(snapshot.recurringCards, 1);
      expect(snapshot.mostDrawnCard, 'The Star');
      expect(snapshot.journeyBeginLabel, contains('2026'));
    });

    test('filterEntries supports favorites filter', () {
      final entries = [
        ReadingHistoryEntry(
          id: 'a',
          date: DateTime(2026, 8, 1),
          spreadType: 'Tek Kart',
          filter: HistorySpreadFilter.single,
          cardName: 'Star',
          cardImageAsset: 's.png',
          aiSummary: 'test',
          moodIcon: Icons.star,
          cardIndex: 0,
          heroTag: 'h1',
          isFavorite: true,
        ),
        ReadingHistoryEntry(
          id: 'b',
          date: DateTime(2026, 8, 2),
          spreadType: 'Tek Kart',
          filter: HistorySpreadFilter.single,
          cardName: 'Moon',
          cardImageAsset: 'm.png',
          aiSummary: 'test',
          moodIcon: Icons.star,
          cardIndex: 0,
          heroTag: 'h2',
        ),
      ];

      final favorites = service.filterEntries(
        entries,
        HistorySpreadFilter.favorites,
        '',
      );

      expect(favorites, hasLength(1));
      expect(favorites.first.id, 'a');
    });
  });

  group('ReadingHistoryTimeline.buildArchive', () {
    test('inserts month markers before day groups', () {
      final entries = [
        ReadingHistoryEntry(
          id: '1',
          date: DateTime(2026, 8, 4),
          spreadType: 'Tek Kart',
          filter: HistorySpreadFilter.single,
          cardName: 'Star',
          cardImageAsset: 's.png',
          aiSummary: 'a',
          moodIcon: Icons.star,
          cardIndex: 0,
          heroTag: 'h1',
        ),
        ReadingHistoryEntry(
          id: '2',
          date: DateTime(2026, 7, 28),
          spreadType: 'Tek Kart',
          filter: HistorySpreadFilter.single,
          cardName: 'Moon',
          cardImageAsset: 'm.png',
          aiSummary: 'b',
          moodIcon: Icons.star,
          cardIndex: 0,
          heroTag: 'h2',
        ),
      ];

      final nodes = ReadingHistoryTimeline.buildArchive(entries);

      expect(nodes[0], isA<ReadingHistoryMonthMarker>());
      expect(nodes[1], isA<ReadingHistoryDayMarker>());
      expect(nodes[2], isA<ReadingHistoryTimelineEntry>());
      expect(nodes[3], isA<ReadingHistoryMonthMarker>());
    });
  });
}
