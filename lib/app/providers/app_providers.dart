/// OR-1100 — Riverpod provider definitions.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/repositories/user_achievement_repository.dart';
import '../../core/domain/repositories/achievement_repository.dart';
import '../../core/intelligence/data/intelligence_index_store.dart';
import '../../core/intelligence/data/local_intelligence_repository.dart';
import '../../core/intelligence/data/ritual_history_reader.dart';
import '../../core/intelligence/domain/repositories/intelligence_repository.dart';
import '../../core/intelligence/services/intelligence_layer_service.dart';
import '../../core/experience/engine/experience_orchestrator.dart';
import '../../core/experience/services/experience_orchestrator_service.dart';
import '../../core/reflection/data/sources/reading_reflection_source.dart';
import '../../features/birth_chart/reflection/birth_chart_reflection_source.dart';
import '../../features/companion/reflection/companion_reflection_source.dart';
import '../../features/dream/reflection/dream_reflection_source.dart';
import '../../core/reflection/engine/reflection_engine.dart';
import '../../core/reflection/services/reflection_engine_service.dart';
import '../../core/providers/backend_providers.dart' as backend;
import '../../core/data/repositories/local_onboarding_repository.dart';
import '../../core/data/repositories/local_settings_repository.dart';
import '../../core/data/repositories/mock_daily_energy_repository.dart';
import '../../core/data/repositories/mock_history_repository.dart';
import '../../core/data/repositories/mock_premium_repository.dart';
import '../../core/data/repositories/mock_tarot_repository.dart';
import '../../core/data/repositories/mock_user_repository.dart';
import '../../core/domain/models/daily_energy.dart';
import '../../core/domain/models/reading.dart';
import '../../core/domain/models/user_profile.dart';
import '../../core/domain/repositories/daily_energy_repository.dart';
import '../../core/domain/repositories/onboarding_repository.dart';
import '../../core/domain/repositories/history_repository.dart';
import '../../core/domain/repositories/premium_repository.dart';
import '../../core/domain/repositories/settings_repository.dart';
import '../../core/domain/repositories/tarot_repository.dart';
import '../../core/domain/repositories/user_repository.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/reading_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/tarot_service.dart';
import '../../features/daily_ritual/services/daily_ritual_service.dart';
import '../../features/insights/services/personal_journey_service.dart';
import '../../core/services/first_session_service.dart';
import '../../features/premium/models/personalization_models.dart';

// ── Infrastructure ─────────────────────────────────────────────────

final localStorageProvider = backend.localStorageProvider;

// ── Repositories ───────────────────────────────────────────────────

final tarotRepositoryProvider = Provider<TarotRepository>((ref) {
  return MockTarotRepository(ref.watch(localStorageProvider));
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return MockHistoryRepository(ref.watch(localStorageProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return MockUserRepository(ref.watch(localStorageProvider));
});

final premiumRepositoryProvider = Provider<PremiumRepository>((ref) {
  return MockPremiumRepository(ref.watch(localStorageProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return LocalSettingsRepository(ref.watch(localStorageProvider));
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return LocalOnboardingRepository(ref.watch(localStorageProvider));
});

final dailyEnergyRepositoryProvider = Provider<DailyEnergyRepository>((ref) {
  return MockDailyEnergyRepository();
});

// ── Services ───────────────────────────────────────────────────────

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return const AnalyticsService();
});

final tarotServiceProvider = Provider<TarotService>((ref) {
  return TarotService(ref.watch(tarotRepositoryProvider));
});

final readingServiceProvider = Provider<ReadingService>((ref) {
  return ReadingService(
    ref.watch(historyRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService(ref.watch(historyRepositoryProvider));
});

final premiumServiceProvider = Provider<PremiumService>((ref) {
  return PremiumService(
    ref.watch(premiumRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(settingsRepositoryProvider));
});

final dailyRitualServiceProvider = Provider<DailyRitualService>((ref) {
  return DailyRitualService(ref.watch(localStorageProvider));
});

final personalJourneyServiceProvider = Provider<PersonalJourneyService>((ref) {
  return const PersonalJourneyService();
});

// ── State providers ────────────────────────────────────────────────

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfileModel>(
  UserProfileNotifier.new,
);

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, PersonalizationSettings>(
  SettingsNotifier.new,
);

final readingHistoryProvider =
    AsyncNotifierProvider<ReadingHistoryNotifier, List<ReadingModel>>(
  ReadingHistoryNotifier.new,
);

final dailyEnergyProvider =
    AsyncNotifierProvider<DailyEnergyNotifier, DailyEnergyModel>(
  DailyEnergyNotifier.new,
);

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return UserAchievementRepository(ref.watch(userRepositoryProvider));
});

// ── Backend infrastructure (OR-1130) ─────────────────────────────

final apiClientProvider = backend.apiClientProvider;
final authServiceProvider = backend.authServiceProvider;
final sessionManagerProvider = backend.sessionManagerProvider;
final tokenManagerProvider = backend.tokenManagerProvider;
final syncQueueProvider = backend.syncQueueProvider;
final backgroundSyncProvider = backend.backgroundSyncProvider;
final dreamRepositoryProvider = backend.dreamRepositoryProvider;
final birthChartRepositoryProvider = backend.birthChartRepositoryProvider;
final astrologyRepositoryProvider = backend.astrologyRepositoryProvider;
final aiConversationRepositoryProvider = backend.aiConversationRepositoryProvider;
final firebaseAnalyticsProvider = backend.firebaseAnalyticsProvider;
final crashlyticsProvider = backend.crashlyticsProvider;
final performanceMonitorProvider = backend.performanceMonitorProvider;

final premiumActiveProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(premiumServiceProvider);
  return service.isActive();
});

final selectedSpreadProvider = StateProvider<String?>((ref) => null);

final selectedDeckProvider = StateProvider<String?>((ref) => null);

// ── Intelligence layer (RC-009) ────────────────────────────────────
// Registered for future personalization — not wired to UI in RC-009.

final ritualHistoryReaderProvider = Provider<RitualHistoryReader>((ref) {
  return RitualHistoryReader(ref.watch(localStorageProvider));
});

final intelligenceIndexStoreProvider = Provider<IntelligenceIndexStore>((ref) {
  return IntelligenceIndexStore(ref.watch(localStorageProvider));
});

final intelligenceRepositoryProvider = Provider<IntelligenceRepository>((ref) {
  return LocalIntelligenceRepository(
    history: ref.watch(historyRepositoryProvider),
    conversations: ref.watch(backend.aiConversationRepositoryProvider),
    ritualHistory: ref.watch(ritualHistoryReaderProvider),
    indexStore: ref.watch(intelligenceIndexStoreProvider),
    journey: ref.watch(personalJourneyServiceProvider),
  );
});

final intelligenceLayerServiceProvider = Provider<IntelligenceLayerService>((ref) {
  return IntelligenceLayerService(ref.watch(intelligenceRepositoryProvider));
});

// ── Reflection engine (RC-010) ─────────────────────────────────────
// Logical heart of long-term understanding — not wired to UI in RC-010.

final reflectionEngineProvider = Provider<ReflectionEngine>((ref) {
  return const ReflectionEngine();
});

final reflectionEngineServiceProvider = Provider<ReflectionEngineService>((ref) {
  final intelligence = ref.watch(intelligenceLayerServiceProvider);
  final dreamRepo = ref.watch(dreamRepositoryProvider);
  final birthChartRepo = ref.watch(birthChartRepositoryProvider);
  final conversationRepo = ref.watch(aiConversationRepositoryProvider);
  return ReflectionEngineService(
    intelligence: intelligence,
    engine: ref.watch(reflectionEngineProvider),
    sources: [
      ReadingReflectionSource(intelligence),
      DreamReflectionSource(dreamRepo),
      BirthChartReflectionSource(birthChartRepo),
      CompanionReflectionSource(conversationRepo),
    ],
  );
});

// ── Experience orchestrator (RC-011) ─────────────────────────────
// Central decision layer — not wired to UI in RC-011.

final experienceOrchestratorProvider = Provider<ExperienceOrchestrator>((ref) {
  return const ExperienceOrchestrator();
});

final experienceOrchestratorServiceProvider =
    Provider<ExperienceOrchestratorService>((ref) {
  return ExperienceOrchestratorService(
    reflection: ref.watch(reflectionEngineServiceProvider),
    dailyRitual: ref.watch(dailyRitualServiceProvider),
    settings: ref.watch(settingsServiceProvider),
    premium: ref.watch(premiumServiceProvider),
    orchestrator: ref.watch(experienceOrchestratorProvider),
  );
});

// ── First session (RC-012) ─────────────────────────────────────────

final firstSessionServiceProvider = Provider<FirstSessionService>((ref) {
  return FirstSessionService(ref.watch(historyRepositoryProvider));
});

final isFirstSessionProvider = FutureProvider<bool>((ref) {
  return ref.watch(firstSessionServiceProvider).isFirstSession();
});

// ── Notifiers ────────────────────────────────────────────────────

class UserProfileNotifier extends AsyncNotifier<UserProfileModel> {
  @override
  Future<UserProfileModel> build() async {
    final repo = ref.watch(userRepositoryProvider);
    return repo.getProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(userRepositoryProvider).getProfile());
  }

  Future<void> saveName(String name) async {
    final repo = ref.read(userRepositoryProvider);
    final current = state.value ?? const UserProfileModel();
    await repo.saveProfile(current.copyWith(name: name));
    await refresh();
  }
}

class SettingsNotifier extends AsyncNotifier<PersonalizationSettings> {
  @override
  Future<PersonalizationSettings> build() async {
    return ref.watch(settingsServiceProvider).load();
  }

  Future<void> saveSettings(PersonalizationSettings settings) async {
    await ref.read(settingsServiceProvider).save(settings);
    state = AsyncData(settings);
  }
}

class ReadingHistoryNotifier extends AsyncNotifier<List<ReadingModel>> {
  @override
  Future<List<ReadingModel>> build() async {
    return ref.watch(historyServiceProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(historyServiceProvider).getAll());
  }
}

class DailyEnergyNotifier extends AsyncNotifier<DailyEnergyModel> {
  @override
  Future<DailyEnergyModel> build() async {
    return ref.watch(dailyEnergyRepositoryProvider).getToday();
  }
}
