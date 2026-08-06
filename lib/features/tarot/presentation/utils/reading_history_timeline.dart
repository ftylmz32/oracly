/// OR-437 / EPIC-012 — Diary-style timeline archive for reading history.
library;

import '../widgets/reading_history/reading_history_data.dart';

/// One calendar day in the personal ritual journal.
class ReadingHistoryDayGroup {
  const ReadingHistoryDayGroup({
    required this.day,
    required this.label,
    required this.entries,
  });

  final DateTime day;
  final String label;
  final List<ReadingHistoryEntry> entries;
}

/// A node in the personal journey archive timeline.
sealed class ReadingHistoryTimelineNode {
  const ReadingHistoryTimelineNode();
}

class ReadingHistoryMonthMarker extends ReadingHistoryTimelineNode {
  const ReadingHistoryMonthMarker(this.label);

  final String label;
}

class ReadingHistoryDayMarker extends ReadingHistoryTimelineNode {
  const ReadingHistoryDayMarker({
    required this.label,
    required this.isFirst,
  });

  final String label;
  final bool isFirst;
}

class ReadingHistoryTimelineEntry extends ReadingHistoryTimelineNode {
  const ReadingHistoryTimelineEntry(this.entry);

  final ReadingHistoryEntry entry;
}

abstract final class ReadingHistoryTimeline {
  ReadingHistoryTimeline._();

  static List<ReadingHistoryDayGroup> groupByDay(
    List<ReadingHistoryEntry> entries,
  ) {
    if (entries.isEmpty) return [];

    final sorted = [...entries]
      ..sort((a, b) => b.date.compareTo(a.date));

    final groups = <ReadingHistoryDayGroup>[];
    DateTime? currentDay;
    List<ReadingHistoryEntry> bucket = [];

    void flush() {
      if (currentDay == null || bucket.isEmpty) return;
      final day = currentDay!;
      groups.add(
        ReadingHistoryDayGroup(
          day: day,
          label: _dayLabel(day),
          entries: List.unmodifiable(bucket),
        ),
      );
      bucket = [];
      currentDay = null;
    }

    for (final entry in sorted) {
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (currentDay == null || day != currentDay) {
        flush();
        currentDay = day;
      }
      bucket.add(entry);
    }
    flush();
    return groups;
  }

  /// Month chapters + day markers + entries — a quiet archive, not a log.
  static List<ReadingHistoryTimelineNode> buildArchive(
    List<ReadingHistoryEntry> entries,
  ) {
    final dayGroups = groupByDay(entries);
    if (dayGroups.isEmpty) return [];

    final nodes = <ReadingHistoryTimelineNode>[];
    int? currentMonthKey;

    for (var i = 0; i < dayGroups.length; i++) {
      final group = dayGroups[i];
      final monthKey = group.day.year * 100 + group.day.month;
      if (currentMonthKey != monthKey) {
        nodes.add(ReadingHistoryMonthMarker(_monthLabel(group.day)));
        currentMonthKey = monthKey;
      }
      nodes.add(
        ReadingHistoryDayMarker(
          label: group.label,
          isFirst: i == 0,
        ),
      );
      for (final entry in group.entries) {
        nodes.add(ReadingHistoryTimelineEntry(entry));
      }
    }
    return nodes;
  }

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(day.year, day.month, day.day);

    if (target == today) return 'Bugün';
    if (target == yesterday) return 'Dün';

    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${day.day} ${months[day.month - 1]} ${day.year}';
  }

  static String _monthLabel(DateTime day) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${months[day.month - 1]} ${day.year}';
  }
}
