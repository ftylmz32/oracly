/// OR-1170 — Maps saved readings to history UI entries.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/oracly_format.dart';
import '../../../../core/domain/models/reading.dart';
import '../../domain/models/tarot_spread.dart';
import '../widgets/reading_history/reading_history_data.dart';

abstract final class ReadingHistoryMapper {
  ReadingHistoryMapper._();

  static ReadingHistoryEntry fromModel(ReadingModel model) {
    return ReadingHistoryEntry(
      id: model.id,
      date: model.createdAt,
      spreadType: model.spreadType,
      filter: _filterForSpread(model.spreadType),
      cardName: model.cardName,
      cardImageAsset: model.cardImageAsset,
      aiSummary: model.aiSummary,
      moodIcon: _iconForSpread(model.spreadType),
      cardIndex: model.cardIndex,
      heroTag: 'history_card_${model.id}',
      emotionalKeywords: model.emotionalKeywords,
      personalNote: model.personalNote,
      summaryExcerpt: model.summaryExcerpt,
      isFavorite: model.isFavorite,
      readingType: _publicType(model),
      isReversed: model.primaryIsReversed,
    );
  }

  static String? _publicType(ReadingModel model) {
    final type = model.readingType?.trim();
    if (type == null || type.isEmpty) return null;
    if (type == model.intention?.trim() &&
        (type.contains('?') || type.length > 24)) {
      return null;
    }
    return type;
  }

  static HistorySpreadFilter _filterForSpread(String spread) {
    final type = TarotSpreadType.fromPersisted(spread);
    return switch (type) {
      TarotSpreadType.single => HistorySpreadFilter.single,
      TarotSpreadType.threeCard => HistorySpreadFilter.three,
      TarotSpreadType.fiveCard || TarotSpreadType.crossroads =>
        HistorySpreadFilter.five,
      TarotSpreadType.celticCross => HistorySpreadFilter.celtic,
      TarotSpreadType.sevenCard || null => HistorySpreadFilter.all,
    };
  }

  static IconData _iconForSpread(String spread) {
    final type = TarotSpreadType.fromPersisted(spread);
    return switch (type) {
      TarotSpreadType.single => Icons.filter_1_rounded,
      TarotSpreadType.threeCard => Icons.filter_3_rounded,
      TarotSpreadType.fiveCard || TarotSpreadType.crossroads =>
        Icons.filter_5_rounded,
      TarotSpreadType.sevenCard => Icons.filter_7_rounded,
      TarotSpreadType.celticCross => Icons.grid_view_rounded,
      null => Icons.auto_awesome_rounded,
    };
  }

  @Deprecated('Use PersonalJourneyService.filterEntries')
  static List<ReadingHistoryEntry> filterEntries(
    List<ReadingHistoryEntry> entries,
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
          e.typeLabel.toLowerCase().contains(q) ||
          (e.readingType?.toLowerCase().contains(q) ?? false) ||
          e.aiSummary.toLowerCase().contains(q) ||
          e.timelineSummary.toLowerCase().contains(q) ||
          (e.personalNote?.toLowerCase().contains(q) ?? false) ||
          e.emotionalKeywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }

  @Deprecated('Use PersonalJourneyService.statsFrom')
  static ReadingHistoryStats statsFrom(List<ReadingHistoryEntry> entries) {
    final now = DateTime.now();
    final thisMonth = entries
        .where(
          (e) => e.date.year == now.year && e.date.month == now.month,
        )
        .length;
    return ReadingHistoryStats(
      totalReadings: entries.length,
      thisMonth: thisMonth,
      notesWritten: entries.where((e) => e.hasPersonalNote).length,
      favoritedMemories: entries.where((e) => e.isFavorite).length,
      recurringCards: _recurringCards(entries),
      journeyBeginLabel: _journeyBeginLabel(entries),
    );
  }

  static int _recurringCards(List<ReadingHistoryEntry> entries) {
    final counts = <String, int>{};
    for (final entry in entries) {
      counts[entry.cardName] = (counts[entry.cardName] ?? 0) + 1;
    }
    return counts.values.where((count) => count >= 2).length;
  }

  static String? _journeyBeginLabel(List<ReadingHistoryEntry> entries) {
    if (entries.isEmpty) return null;
    final oldest =
        entries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    return OraclyFormat.monthYear(oldest);
  }
}
