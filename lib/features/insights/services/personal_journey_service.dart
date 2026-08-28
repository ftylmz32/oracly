/// EPIC-012 — Personal journey composer — observable patterns from user history.
library;

import '../../../core/domain/models/reading.dart';
import '../../../core/history/history_scale_policy.dart';
import '../../../core/l10n/oracly_format.dart';
import '../../tarot/presentation/utils/reading_history_timeline.dart';
import '../../tarot/presentation/widgets/reading_history/reading_history_data.dart';
import '../models/personal_journey_snapshot.dart';
import 'personal_insight_engine.dart';

/// Composes journey memory from saved readings — no predictions, no fabrication.
class PersonalJourneyService {
  const PersonalJourneyService();

  PersonalJourneySnapshot compose(List<ReadingModel> readings) {
    final window = HistoryScalePolicy.newestByDate(
      readings,
      (r) => r.createdAt,
    );
    final insightReport = PersonalInsightEngine.analyze(
      window,
      totalReadings: readings.length,
    );
    final notesWritten = readings
        .where((r) => r.personalNote != null && r.personalNote!.trim().isNotEmpty)
        .length;
    final favoritedMemories = readings.where((r) => r.isFavorite).length;
    final cardCounts = <String, int>{};
    for (final reading in readings) {
      cardCounts[reading.cardName] = (cardCounts[reading.cardName] ?? 0) + 1;
    }
    final recurringCards =
        cardCounts.values.where((count) => count >= 2).length;
    final mostDrawn = cardCounts.entries.isEmpty
        ? null
        : cardCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return PersonalJourneySnapshot(
      totalReadings: readings.length,
      notesWritten: notesWritten,
      favoritedMemories: favoritedMemories,
      recurringCards: recurringCards,
      insightReport: insightReport,
      journeyBeginLabel: _journeyBeginLabel(readings),
      mostDrawnCard: (mostDrawn?.value ?? 0) >= 2 ? mostDrawn!.key : null,
    );
  }

  ReadingHistoryStats statsFrom(List<ReadingHistoryEntry> entries) {
    final now = DateTime.now();
    final thisMonth = entries
        .where(
          (e) => e.date.year == now.year && e.date.month == now.month,
        )
        .length;
    final notesWritten = entries.where((e) => e.hasPersonalNote).length;
    final favoritedMemories = entries.where((e) => e.isFavorite).length;
    final cardCounts = <String, int>{};
    for (final entry in entries) {
      cardCounts[entry.cardName] = (cardCounts[entry.cardName] ?? 0) + 1;
    }
    final recurringCards =
        cardCounts.values.where((count) => count >= 2).length;

    return ReadingHistoryStats(
      totalReadings: entries.length,
      thisMonth: thisMonth,
      notesWritten: notesWritten,
      favoritedMemories: favoritedMemories,
      recurringCards: recurringCards,
      journeyBeginLabel: _journeyBeginLabelFromEntries(entries),
    );
  }

  List<ReadingHistoryEntry> filterEntries(
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
          (e.readingType?.toLowerCase().contains(q) ?? false) ||
          e.aiSummary.toLowerCase().contains(q) ||
          e.timelineSummary.toLowerCase().contains(q) ||
          (e.personalNote?.toLowerCase().contains(q) ?? false) ||
          e.emotionalKeywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }

  List<ReadingHistoryTimelineNode> buildTimeline(
    List<ReadingHistoryEntry> entries,
  ) =>
      ReadingHistoryTimeline.buildArchive(entries);

  String? _journeyBeginLabel(List<ReadingModel> readings) {
    if (readings.isEmpty) return null;
    final oldest = readings
        .map((r) => r.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return _formatMonthYear(oldest);
  }

  String? _journeyBeginLabelFromEntries(List<ReadingHistoryEntry> entries) {
    if (entries.isEmpty) return null;
    final oldest =
        entries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    return _formatMonthYear(oldest);
  }

  static String _formatMonthYear(DateTime date) => OraclyFormat.monthYear(date);
}
