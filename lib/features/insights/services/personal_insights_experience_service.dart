/// SPRINT-004 — Personal Insights experience orchestrator.
library;

import '../../../core/reflection/services/reflection_engine_service.dart';
import '../data/personal_insights_preferences_repository.dart';
import '../models/insight.dart';
import '../models/reflection_summary.dart';
import '../services/personal_insight_engine.dart';
import '../services/personal_insights_mapper.dart';
import '../copy/personal_insights_copy.dart';

class PersonalInsightsExperienceService {
  PersonalInsightsExperienceService({
    required ReflectionEngineService reflectionEngine,
    required PersonalInsightsPreferencesRepository preferences,
  })  : _reflectionEngine = reflectionEngine,
        _preferences = preferences;

  final ReflectionEngineService _reflectionEngine;
  final PersonalInsightsPreferencesRepository _preferences;

  Future<InsightReflectionSummary> generate({DateTime? asOf}) async {
    final prefs = await _preferences.load();
    final input = await _reflectionEngine.buildInput(asOf: asOf);
    final reflection = _reflectionEngine.analyzeInput(input);
    final tarotReport = PersonalInsightEngine.analyze(input.readings);

    return PersonalInsightsMapper.compose(
      reflection: reflection,
      tarotReport: tarotReport,
      input: input,
      excludedIds: prefs.deletedIds,
    );
  }

  Future<InsightReflectionSummary> applyPrivacyFilters(
    InsightReflectionSummary summary,
  ) async {
    final prefs = await _preferences.load();
    final visible = summary.insights
        .where((i) => !prefs.hiddenIds.contains(i.id))
        .toList();

    return InsightReflectionSummary(
      salutation: summary.salutation,
      closingNote: summary.closingNote,
      generatedAt: summary.generatedAt,
      insights: visible,
      growthSnapshot: summary.growthSnapshot,
      patterns: summary.patterns,
    );
  }

  Future<void> hideInsight(String id) => _preferences.hide(id);

  Future<void> deleteInsight(String id) => _preferences.delete(id);

  String exportAsText(InsightReflectionSummary summary) {
    final buffer = StringBuffer()
      ..writeln(PersonalInsightsCopy.exportHeader)
      ..writeln()
      ..writeln(summary.salutation)
      ..writeln();

    final growth = summary.growthSnapshot;
    if (growth != null && growth.narrative.trim().isNotEmpty) {
      buffer
        ..writeln('— Büyüme —')
        ..writeln(growth.narrative)
        ..writeln();
    }

    for (final insight in summary.insights) {
      buffer
        ..writeln('— ${insight.title} —')
        ..writeln(insight.body)
        ..writeln();
    }

    if (summary.patterns.isNotEmpty) {
      buffer.writeln('— Desenler —');
      for (final pattern in summary.patterns) {
        buffer.writeln('• ${pattern.label}: ${pattern.observation}');
      }
      buffer.writeln();
    }

    if (summary.closingNote != null) {
      buffer.writeln(summary.closingNote);
    }

    return buffer.toString().trim();
  }

  List<Insight> visibleInsights(
    InsightReflectionSummary summary,
    PersonalInsightsPreferences prefs,
  ) {
    return summary.insights
        .where(
          (i) =>
              !prefs.hiddenIds.contains(i.id) &&
              !prefs.deletedIds.contains(i.id),
        )
        .toList();
  }
}
