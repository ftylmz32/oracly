/// OR-1070 — Reading history models and sample journal data.
library;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/l10n/oracly_format.dart';
import '../../../copy/tarot_l10n.dart';

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

  String get displayLabel => OraclyL10n.t('tarot.hist.filter.$name');
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
    this.readingType,
    this.isReversed = false,
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
  final String? readingType;
  final bool isReversed;

  String get timelineSummary => summaryExcerpt ?? aiSummary;

  bool get hasPersonalNote =>
      personalNote != null && personalNote!.trim().isNotEmpty;

  String get typeLabel {
    final spread = TarotL10n.spreadFromStorage(spreadType);
    final type = readingType?.trim();
    if (type == null || type.isEmpty || type == spreadType) return spread;
    return '$type · $spread';
  }

  String get timeLabel => OraclyFormat.time(date);

  String get dateLabel => OraclyFormat.dateCompact(date);
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

  static const _root = 'lib/assets/images/tarot/major_arcana';

  static const stats = ReadingHistoryStats(
    totalReadings: 12,
    thisMonth: 4,
    notesWritten: 3,
    favoritedMemories: 2,
    recurringCards: 1,
    journeyBeginLabel: null,
  );

  static final List<ReadingHistoryEntry> entries = [
    ReadingHistoryEntry(
      id: 'h1',
      date: DateTime(2026, 8, 4, 21, 14),
      spreadType: 'Tek Kart',
      filter: HistorySpreadFilter.single,
      cardName: 'The Star',
      cardImageAsset: '$_root/17_yildiz.png',
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
      cardImageAsset: '$_root/18_ay.png',
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
      cardImageAsset: '$_root/19_gunes.png',
      aiSummary:
          'Aydınlanma ve neşe daha seçilir. Cesur adımlar destekleniyor.',
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
      cardImageAsset: '$_root/06_asiklar.png',
      aiSummary:
          'Kalbin sesi netleşiyor. Önemli bir seçim veya derin bir bağ tonu.',
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
      cardImageAsset: '$_root/09_ermis.png',
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
      cardImageAsset: '$_root/13_olum.png',
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
          (e.readingType?.toLowerCase().contains(q) ?? false) ||
          e.aiSummary.toLowerCase().contains(q) ||
          e.timelineSummary.toLowerCase().contains(q) ||
          (e.personalNote?.toLowerCase().contains(q) ?? false) ||
          e.emotionalKeywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }
}
