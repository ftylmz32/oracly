/// RC-010 — Detects repeated reflection topics in journal entries.
library;

import '../../domain/models/recurring_theme.dart';
import '../../domain/models/reflection_evidence_kind.dart';
import '../../domain/models/reflection_input.dart';
import '../reflection_engine_thresholds.dart';

abstract final class ReflectionTopicAnalyzer {
  ReflectionTopicAnalyzer._();

  static const _topicLabels = <String, String>{
    'umut': 'Umut',
    'huzur': 'Huzur',
    'sakin': 'Sakinlik',
    'sabır': 'Sabır',
    'sabir': 'Sabır',
    'dönüşüm': 'Dönüşüm',
    'donusum': 'Dönüşüm',
    'aşk': 'Aşk',
    'ask': 'Aşk',
    'sevgi': 'Sevgi',
    'bağ': 'Bağ',
    'bag': 'Bağ',
    'sezgi': 'Sezgi',
    'cesaret': 'Cesaret',
    'korku': 'Korku',
    'endişe': 'Endişe',
    'endise': 'Endişe',
    'netlik': 'Netlik',
    'denge': 'Denge',
    'yolculuk': 'Yolculuk',
    'ruhsal': 'Ruhsal',
  };

  static List<RecurringTheme> analyze(ReflectionInput input) {
    final topicDates = <String, List<DateTime>>{};

    for (final reading in input.readings) {
      for (final keyword in reading.emotionalKeywords) {
        topicDates.putIfAbsent(keyword, () => []).add(reading.createdAt);
      }
    }

    for (final reflection in input.reflections) {
      final normalized = reflection.text.toLowerCase();
      for (final entry in _topicLabels.entries) {
        if (normalized.contains(entry.key)) {
          topicDates.putIfAbsent(entry.value, () => []).add(reflection.recordedAt);
        }
      }
    }

    return topicDates.entries
        .where(
          (entry) =>
              entry.value.length >=
              ReflectionEngineThresholds.minJournalTopicOccurrences,
        )
        .map((entry) {
          entry.value.sort();
          return RecurringTheme(
            id: 'topic:${entry.key.toLowerCase()}',
            label: entry.key,
            occurrenceCount: entry.value.length,
            firstObserved: entry.value.first,
            lastObserved: entry.value.last,
            evidence: ReflectionEvidenceKind.journalTopic,
          );
        })
        .toList();
  }
}
