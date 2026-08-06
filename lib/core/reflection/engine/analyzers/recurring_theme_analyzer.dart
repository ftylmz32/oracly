/// RC-010 — Detects recurring themes from reading history.
library;

import '../../../domain/models/reading.dart';
import '../../../../features/insights/services/personal_insight_engine.dart';
import '../../domain/models/recurring_theme.dart';
import '../../domain/models/reflection_evidence_kind.dart';
import '../../domain/models/reflection_input.dart';
import '../reflection_engine_thresholds.dart';

abstract final class RecurringThemeAnalyzer {
  RecurringThemeAnalyzer._();

  static List<RecurringTheme> analyze(ReflectionInput input) {
    if (input.readings.length < ReflectionEngineThresholds.minReadingsForThemes) {
      return const [];
    }

    final report = PersonalInsightEngine.analyze(input.readings);
    final themesByReading = <String, List<DateTime>>{};

    for (final reading in input.readings) {
      for (final echo in report.recurringThemes) {
        final dates = themesByReading.putIfAbsent(echo.theme.id, () => []);
        if (_readingHasTheme(reading, echo.theme.id)) {
          dates.add(reading.createdAt);
        }
      }
    }

    return report.recurringThemes.map((echo) {
      final dates = themesByReading[echo.theme.id] ?? const <DateTime>[];
      dates.sort();
      return RecurringTheme(
        id: echo.theme.id,
        label: echo.theme.label,
        occurrenceCount: echo.count,
        firstObserved: dates.isEmpty ? input.readings.first.createdAt : dates.first,
        lastObserved: dates.isEmpty ? input.readings.last.createdAt : dates.last,
        evidence: ReflectionEvidenceKind.themeTag,
      );
    }).toList();
  }

  static bool _readingHasTheme(ReadingModel reading, String themeId) {
    if (reading.journal.tags.any((tag) => tag == 'insight:$themeId')) {
      return true;
    }
    final detected = PersonalInsightEngine.tagsForReading(
      aiSummary: reading.aiSummary,
      cardName: reading.cardName,
      intention: reading.intention,
    );
    return detected.any((tag) => tag == 'insight:$themeId');
  }
}
