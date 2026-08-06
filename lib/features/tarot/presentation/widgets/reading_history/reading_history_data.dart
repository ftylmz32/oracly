/// OR-1070 — Reading history models and sample journal data.
library;

import 'package:flutter/material.dart';

/// Spread filter categories for the history journal.
enum HistorySpreadFilter {
  all('Tümü'),
  favorites('Hatıralar'),
  single('Tek Kart'),
  three('Üç Kart Açılımı'),
  five('Beş Kart'),
  celtic('Kelt Haçı');

  const HistorySpreadFilter(this.label);
  final String label;
}

/// One saved tarot reading in the personal journal.
class ReadingHistoryEntry {
  const ReadingHistoryEntry({
    required this.id,
    required this.date,
    required this.spreadType,
    required this.filter,
    required this.cardName,
    required this.cardImageAsset,
    required this.aiSummary,
    required this.moodIcon,
    required this.cardIndex,
    required this.heroTag,
    this.emotionalKeywords = const [],
    this.personalNote,
    this.summaryExcerpt,
    this.isFavorite = false,
  });

  final String id;
  final DateTime date;
  final String spreadType;
  final HistorySpreadFilter filter;
  final String cardName;
  final String cardImageAsset;
  final String aiSummary;
  final IconData moodIcon;
  final int cardIndex;
  final String heroTag;
  final List<String> emotionalKeywords;
  final String? personalNote;
  final String? summaryExcerpt;
  final bool isFavorite;

  String get timelineSummary => summaryExcerpt ?? aiSummary;

  bool get hasPersonalNote =>
      personalNote != null && personalNote!.trim().isNotEmpty;

  String get timeLabel {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get dateLabel {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Memory-oriented archive summary — not gamified statistics.
class ReadingHistoryStats {
  const ReadingHistoryStats({
    required this.totalReadings,
    required this.thisMonth,
    required this.notesWritten,
    required this.favoritedMemories,
    required this.recurringCards,
    this.journeyBeginLabel,
  });

  final int totalReadings;
  final int thisMonth;
  final int notesWritten;
  final int favoritedMemories;
  final int recurringCards;
  final String? journeyBeginLabel;
}

abstract final class ReadingHistoryCatalogue {
  ReadingHistoryCatalogue._();

  static const _root = 'lib/assets/images/cards/tarot/major';

  static const stats = ReadingHistoryStats(
    totalReadings: 12,
    thisMonth: 4,
    notesWritten: 3,
    favoritedMemories: 2,
    recurringCards: 1,
    journeyBeginLabel: 'Temmuz 2026',
  );

  static final List<ReadingHistoryEntry> entries = [
    ReadingHistoryEntry(
      id: 'h1',
      date: DateTime(2026, 8, 4, 21, 14),
      spreadType: 'Tek Kart',
      filter: HistorySpreadFilter.single,
      cardName: 'The Star',
      cardImageAsset: '$_root/17-TheStar.png',
      aiSummary:
          'Umut ve ilahi rehberlik seninle. Kalbine huzur taşıyan bir döneme giriyorsun.',
      moodIcon: Icons.auto_awesome_rounded,
      cardIndex: 0,
      heroTag: 'history_card_h1',
      emotionalKeywords: ['Umut', 'Huzur', 'Rehberlik'],
      summaryExcerpt:
          'Umut ve ilahi rehberlik seninle. Kalbine huzur taşıyan bir döneme giriyorsun.',
      personalNote: 'Bugün bu gerçekten doğru hissettirdi.',
      isFavorite: true,
    ),
    ReadingHistoryEntry(
      id: 'h2',
      date: DateTime(2026, 8, 2, 19, 42),
      spreadType: 'Üç Kart Açılımı',
      filter: HistorySpreadFilter.three,
      cardName: 'The Moon',
      cardImageAsset: '$_root/18-TheMoon.png',
      aiSummary:
          'Sezgi güçleniyor. Bilinçaltının mesajlarına kulak ver; her şey göründüğü gibi değil.',
      moodIcon: Icons.nightlight_round,
      cardIndex: 1,
      heroTag: 'history_card_h2',
      emotionalKeywords: ['Sezgi', 'Belirsizlik', 'Yansıma'],
      summaryExcerpt:
          'Sezgi güçleniyor. Bilinçaltının mesajlarına kulak ver…',
      isFavorite: true,
    ),
    ReadingHistoryEntry(
      id: 'h3',
      date: DateTime(2026, 7, 28, 14, 08),
      spreadType: 'Beş Kart',
      filter: HistorySpreadFilter.five,
      cardName: 'The Sun',
      cardImageAsset: '$_root/19-TheSun.png',
      aiSummary:
          'Aydınlanma ve neşe enerjisi hakim. Cesur adımlar destekleniyor.',
      moodIcon: Icons.wb_sunny_rounded,
      cardIndex: 2,
      heroTag: 'history_card_h3',
    ),
    ReadingHistoryEntry(
      id: 'h4',
      date: DateTime(2026, 7, 22, 22, 31),
      spreadType: 'Kelt Haçı',
      filter: HistorySpreadFilter.celtic,
      cardName: 'The Lovers',
      cardImageAsset: '$_root/06-TheLovers.png',
      aiSummary:
          'Kalbin sesi netleşiyor. Önemli bir seçim veya derin bir bağ enerjisi.',
      moodIcon: Icons.favorite_rounded,
      cardIndex: 3,
      heroTag: 'history_card_h4',
    ),
    ReadingHistoryEntry(
      id: 'h5',
      date: DateTime(2026, 7, 15, 10, 55),
      spreadType: 'Tek Kart',
      filter: HistorySpreadFilter.single,
      cardName: 'The Hermit',
      cardImageAsset: '$_root/09-TheHermit.png',
      aiSummary:
          'İçsel bilgelik ön planda. Cevaplar dışarıda değil, içinde.',
      moodIcon: Icons.self_improvement_rounded,
      cardIndex: 4,
      heroTag: 'history_card_h5',
    ),
    ReadingHistoryEntry(
      id: 'h6',
      date: DateTime(2026, 7, 8, 18, 20),
      spreadType: 'Üç Kart Açılımı',
      filter: HistorySpreadFilter.three,
      cardName: 'Death',
      cardImageAsset: '$_root/13-Death.png',
      aiSummary:
          'Dönüşüm kapıda. Eski bir döngü kapanıyor; yenilenmeye hazır ol.',
      moodIcon: Icons.change_circle_outlined,
      cardIndex: 5,
      heroTag: 'history_card_h6',
    ),
  ];

  static List<ReadingHistoryEntry> filterBy(
    HistorySpreadFilter filter,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    return entries.where((e) {
      final matchesFilter = switch (filter) {
        HistorySpreadFilter.all => true,
        HistorySpreadFilter.favorites => e.isFavorite,
        _ => e.filter == filter,
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return e.cardName.toLowerCase().contains(q) ||
          e.spreadType.toLowerCase().contains(q) ||
          e.aiSummary.toLowerCase().contains(q) ||
          e.timelineSummary.toLowerCase().contains(q) ||
          (e.personalNote?.toLowerCase().contains(q) ?? false) ||
          e.emotionalKeywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }
}
