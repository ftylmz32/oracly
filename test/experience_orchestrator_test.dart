/// RC-011 — Experience orchestrator tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_ai_conversation_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/experience/domain/models/experience_feature_flags.dart';
import 'package:oracly_new/core/experience/domain/models/experience_orchestrator_input.dart';
import 'package:oracly_new/core/experience/domain/models/greeting_context.dart';
import 'package:oracly_new/core/experience/domain/models/recommendation_context.dart';
import 'package:oracly_new/core/experience/domain/models/reflection_context.dart';
import 'package:oracly_new/core/experience/engine/experience_orchestrator.dart';
import 'package:oracly_new/core/experience/services/experience_orchestrator_service.dart';
import 'package:oracly_new/core/intelligence/data/intelligence_index_store.dart';
import 'package:oracly_new/core/intelligence/data/local_intelligence_repository.dart';
import 'package:oracly_new/core/intelligence/data/ritual_history_reader.dart';
import 'package:oracly_new/core/intelligence/services/intelligence_layer_service.dart';
import 'package:oracly_new/core/reflection/engine/reflection_engine.dart';
import 'package:oracly_new/core/reflection/services/reflection_engine_service.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/services/settings_service.dart';
import 'package:oracly_new/core/universe/oracly_ritual_time.dart';
import 'package:oracly_new/features/daily_ritual/models/daily_ritual_day.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_service.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/reflection/domain/models/reflection_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ExperienceOrchestrator', () {
    const orchestrator = ExperienceOrchestrator();
    final asOf = DateTime(2026, 8, 6, 8);

    test('new journey recommends invitation greeting and reading highlight', () {
      final context = orchestrator.decide(
        _input(
          asOf: asOf,
          ritualTime: OraclyRitualTime.morning,
          totalReadings: 0,
        ),
      );

      expect(context.greeting.tone, GreetingTone.newJourney);
      expect(context.reflection.style, ReflectionStyle.invitation);
      expect(context.journey.highlightTodaysRitual, isTrue);
      expect(context.recommendations.primaryHighlight,
          ExperienceHighlight.dailyRitual);
    });

    test('returning user with patterns surfaces observational reflection', () {
      final summary = ReflectionSummary(
        generatedAt: asOf,
        schemaVersion: 1,
        recurringThemes: const [],
        growthInsights: const [],
        milestones: const [],
        trends: const [],
      );

      final context = orchestrator.decide(
        ExperienceOrchestratorInput(
          asOf: asOf,
          ritualTime: OraclyRitualTime.evening,
          reflectionSummary: summary,
          ritualToday: const DailyRitualDay(),
          settings: const PersonalizationSettings(),
          premiumActive: false,
          aiAvailable: true,
          featureFlags: ExperienceFeatureFlags.defaults(),
          totalReadings: 4,
          reflectionCount: 0,
        ),
      );

      expect(context.greeting.tone, GreetingTone.returning);
      expect(context.reflection.style, ReflectionStyle.gentle);
      expect(
        context.recommendations.secondaryHighlights,
        contains(ExperienceHighlight.journal),
      );
    });

    test('night ritual time prefers quiet reflection style', () {
      final context = orchestrator.decide(
        _input(
          asOf: DateTime(2026, 8, 6, 22),
          ritualTime: OraclyRitualTime.night,
          totalReadings: 2,
        ),
      );

      expect(context.reflection.style, ReflectionStyle.quiet);
      expect(context.reflection.preferShortForm, isTrue);
    });

    test('premium relevance stays off for active subscribers', () {
      final context = orchestrator.decide(
        _input(
          asOf: asOf,
          ritualTime: OraclyRitualTime.morning,
          totalReadings: 10,
          premiumActive: true,
        ),
      );

      expect(context.recommendations.premium.isRelevant, isFalse);
    });
  });

  group('ExperienceOrchestratorService', () {
    test('builds context from intelligence and reflection layers', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final history = MockHistoryRepository(storage);
      await history.saveReading(
        ReadingModel(
          id: 'r1',
          cardId: 1,
          cardName: 'The Fool',
          cardImageAsset: 'assets/fool.png',
          spreadType: 'Tek Kart',
          aiSummary: 'Başlangıç.',
          createdAt: DateTime(2026, 8, 1),
        ),
      );

      final intelligence = IntelligenceLayerService(
        LocalIntelligenceRepository(
          history: history,
          conversations: LocalAiConversationRepository(storage),
          ritualHistory: RitualHistoryReader(storage),
          indexStore: IntelligenceIndexStore(storage),
        ),
      );
      final reflection = ReflectionEngineService(
        intelligence: intelligence,
        engine: const ReflectionEngine(),
      );
      final service = ExperienceOrchestratorService(
        reflection: reflection,
        dailyRitual: DailyRitualService(storage),
        settings: SettingsService(LocalSettingsRepository(storage)),
        premium: PremiumService(MockPremiumRepository(storage), MockUserRepository(storage)),
      );

      final context = await service.decide(asOf: DateTime(2026, 8, 6, 8));
      expect(context.schemaVersion, greaterThan(0));
      expect(context.journey.totalReadings, 1);
    });
  });
}

ExperienceOrchestratorInput _input({
  required DateTime asOf,
  required OraclyRitualTime ritualTime,
  required int totalReadings,
  bool premiumActive = false,
}) {
  return ExperienceOrchestratorInput(
    asOf: asOf,
    ritualTime: ritualTime,
    reflectionSummary: ReflectionSummary(
      generatedAt: asOf,
      schemaVersion: 1,
      recurringThemes: const [],
      growthInsights: const [],
      milestones: const [],
      trends: const [],
    ),
    ritualToday: const DailyRitualDay(),
    settings: const PersonalizationSettings(),
    premiumActive: premiumActive,
    aiAvailable: true,
    featureFlags: ExperienceFeatureFlags.defaults(),
    totalReadings: totalReadings,
    reflectionCount: 0,
  );
}
