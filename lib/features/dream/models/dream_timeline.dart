/// SPRINT-001 — Timeline grouping for dream history.
library;

import 'dream.dart';

class DreamTimelineEntry {
  const DreamTimelineEntry({
    required this.dream,
    this.isFirstInDay = false,
  });

  final Dream dream;
  final bool isFirstInDay;
}

class DreamTimeline {
  const DreamTimeline({required this.entries});

  final List<DreamTimelineEntry> entries;

  static DreamTimeline fromDreams(List<Dream> dreams) {
    if (dreams.isEmpty) return const DreamTimeline(entries: []);

    final sorted = [...dreams]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    final entries = <DreamTimelineEntry>[];
    DateTime? lastDay;

    for (final dream in sorted) {
      final day = DateTime(
        dream.recordedAt.year,
        dream.recordedAt.month,
        dream.recordedAt.day,
      );
      final isFirst = lastDay == null || day != lastDay;
      entries.add(DreamTimelineEntry(dream: dream, isFirstInDay: isFirst));
      lastDay = day;
    }

    return DreamTimeline(entries: entries);
  }
}
