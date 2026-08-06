import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/models/personal_insight_report.dart';
import 'package:oracly_new/core/intelligence/domain/models/reflection_entry.dart';
import 'package:oracly_new/core/reflection/domain/models/growth_insight.dart';
import 'package:oracly_new/core/reflection/domain/models/journey_milestone.dart';
import 'package:oracly_new/core/reflection/domain/models/personal_trend.dart';
import 'package:oracly_new/core/reflection/domain/models/recurring_theme.dart';
import 'package:oracly_new/core/reflection/domain/models/reflection_evidence_kind.dart';
import 'package:oracly_new/core/reflection/domain/models/reflection_input.dart';
import 'package:oracly_new/core/reflection/domain/models/reflection_summary.dart'
    as core;
import 'package:oracly_new/features/insights/models/insight_category.dart';
import 'package:oracly_new/features/insights/services/personal_insight_engine.dart';
import 'package:oracly_new/features/insights/data/personal_insights_preferences_repository.dart';
import 'package:oracly_new/features/insights/services/personal_insights_mapper.dart';
import 'package:oracly_new/features/insights/copy/personal_insights_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PersonalInsightsMapper', () {
    final asOf = DateTime(2026, 8, 1);

    test('never invents insights when reflection is empty', () {
      final summary = PersonalInsightsMapper.compose(
        reflection: core.ReflectionSummary(
          generatedAt: asOf,
          schemaVersion: 1,
          recurringThemes: const [],
          growthInsights: const [],
          milestones: const [],
          trends: const [],
        ),
        tarotReport: const PersonalInsightReport(
          recurringThemes: [],
          totalReadings: 0,
        ),
        input: ReflectionInput(
          readings: const [],
          reflections: const [],
          favoriteCards: const [],
          ritualDays: const [],
          asOf: asOf,
        ),
        excludedIds: const {},
      );

      expect(summary.hasContent, isFalse);
      expect(summary.insights, isEmpty);
    });

    test('maps observable themes without percentage language', () {
      final reflection = core.ReflectionSummary(
        generatedAt: asOf,
        schemaVersion: 1,
        recurringThemes: [
          RecurringTheme(
            id: 'love',
            label: 'Aşk',
            occurrenceCount: 3,
            firstObserved: asOf.subtract(const Duration(days: 30)),
            lastObserved: asOf,
            evidence: ReflectionEvidenceKind.themeTag,
          ),
        ],
        growthInsights: [
          GrowthInsight(
            id: 'shift_love',
            kind: GrowthInsightKind.shiftingFocus,
            observation: 'Son dönemde okumaların sık sık aşk temasına değindi.',
            observedAt: asOf,
          ),
        ],
        milestones: [
          JourneyMilestone(
            id: 'first',
            kind: JourneyMilestoneKind.firstReading,
            reachedAt: asOf.subtract(const Duration(days: 60)),
            label: 'İlk açılımın kayda geçti.',
          ),
        ],
        trends: const [],
      );

      final summary = PersonalInsightsMapper.compose(
        reflection: reflection,
        tarotReport: const PersonalInsightReport(
          recurringThemes: [],
          totalReadings: 3,
        ),
        input: ReflectionInput(
          readings: const [],
          reflections: const [],
          favoriteCards: const [],
          ritualDays: const [],
          asOf: asOf,
        ),
        excludedIds: const {},
      );

      expect(summary.insights, isNotEmpty);
      expect(
        summary.insights.any(
          (i) => i.category == InsightCategory.recurringTheme,
        ),
        isTrue,
      );
      for (final insight in summary.insights) {
        expect(insight.body, isNot(contains('%')));
        expect(insight.body, isNot(contains('kesin')));
      }
    });

    test('excludes deleted insight ids', () {
      final reflection = core.ReflectionSummary(
        generatedAt: asOf,
        schemaVersion: 1,
        recurringThemes: [
          RecurringTheme(
            id: 'love',
            label: 'Aşk',
            occurrenceCount: 2,
            firstObserved: asOf,
            lastObserved: asOf,
            evidence: ReflectionEvidenceKind.themeTag,
          ),
        ],
        growthInsights: const [],
        milestones: const [],
        trends: const [],
      );

      final summary = PersonalInsightsMapper.compose(
        reflection: reflection,
        tarotReport: const PersonalInsightReport(
          recurringThemes: [],
          totalReadings: 2,
        ),
        input: ReflectionInput(
          readings: const [],
          reflections: const [],
          favoriteCards: const [],
          ritualDays: const [],
          asOf: asOf,
        ),
        excludedIds: {'insight_theme_love'},
      );

      expect(summary.insights, isEmpty);
    });
  });

  group('PersonalInsightsPreferencesRepository', () {
    late LocalStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await LocalStorage.open();
    });

    test('hide and delete persist preferences', () async {
      final prefsRepo = PersonalInsightsPreferencesRepository(storage);

      await prefsRepo.hide('insight_theme_love');
      var prefs = await prefsRepo.load();
      expect(prefs.hiddenIds, contains('insight_theme_love'));

      await prefsRepo.delete('insight_theme_love');
      prefs = await prefsRepo.load();
      expect(prefs.deletedIds, contains('insight_theme_love'));
      expect(prefs.hiddenIds, isNot(contains('insight_theme_love')));
    });
  });

  group('PersonalInsightsCopy', () {
    test('export header avoids dashboard language', () {
      expect(PersonalInsightsCopy.exportHeader, isNot(contains('%')));
      expect(PersonalInsightsCopy.salutation, isNot(contains('kesin')));
    });
  });

  group('PersonalInsightEngine integration', () {
    test('requires minimum readings before theme patterns', () {
      final readings = List.generate(
        2,
        (i) => ReadingModel(
          id: 'r$i',
          cardId: i,
          cardName: 'The Star',
          cardImageAsset: '',
          spreadType: 'single',
          aiSummary: 'aşk ve sevgi',
          createdAt: DateTime(2026, 7, i + 1),
        ),
      );

      final report = PersonalInsightEngine.analyze(readings);
      expect(report.recurringThemes, isEmpty);
    });
  });
}
