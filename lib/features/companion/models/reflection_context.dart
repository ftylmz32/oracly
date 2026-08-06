/// SPRINT-003 — Journey context for companion responses.
library;

import 'memory.dart';

class ReflectionContext {
  const ReflectionContext({
    this.userName,
    this.savedMemories = const [],
    this.recentReflectionTexts = const [],
    this.recurringThemes = const [],
    this.readingCount = 0,
    this.dreamCount = 0,
    this.hasBirthChart = false,
    this.ritualDaysCount = 0,
    this.unfinishedJournalHint,
    this.proactiveAcknowledgment,
  });

  final String? userName;
  final List<Memory> savedMemories;
  final List<String> recentReflectionTexts;
  final List<String> recurringThemes;
  final int readingCount;
  final int dreamCount;
  final bool hasBirthChart;
  final int ritualDaysCount;
  final String? unfinishedJournalHint;
  final String? proactiveAcknowledgment;

  bool get hasJourneyMemory =>
      readingCount > 0 ||
      dreamCount > 0 ||
      hasBirthChart ||
      savedMemories.isNotEmpty;

  bool get shouldAcknowledgeProactively =>
      proactiveAcknowledgment != null &&
      proactiveAcknowledgment!.trim().isNotEmpty;
}
