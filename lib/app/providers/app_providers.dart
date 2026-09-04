/// OR-1100 — Riverpod provider definitions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_appearance.dart';
import '../../core/data/repositories/user_achievement_repository.dart';
import '../../core/domain/repositories/achievement_repository.dart';
import '../../core/intelligence/data/intelligence_index_store.dart';
import '../../core/intelligence/data/local_intelligence_repository.dart';
import '../../core/intelligence/data/personal_memory_store.dart';
import '../../core/intelligence/data/ritual_history_reader.dart';
import '../../core/intelligence/domain/repositories/intelligence_repository.dart';
import '../../core/intelligence/services/intelligence_layer_service.dart';
import '../../core/intelligence/services/personal_memory_service.dart';
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
import '../../core/analytics/product_analytics.dart';
import '../../core/services/analytics_service.dart';
import '../../features/quality_loop/providers/quality_loop_providers.dart';
import '../../core/telemetry/crash_telemetry_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/reading_service.dart';
import '../../features/premium/providers/premium_purchase_port_provider.dart';
import '../../features/premium/providers/premium_entitlement_verifier_provider.dart';
import '../../features/premium/providers/review_access_provider.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/tarot_service.dart';
import '../../core/audio/oracly_feedback_gate.dart';
import '../../core/audio/oracly_sound_service.dart';
import '../../core/voice/oracly_device_tts.dart';
import '../../core/voice/oracly_proxy_speech.dart';
import '../../core/voice/oracly_reply_tts.dart';
import '../../core/voice/oracly_tts_gate.dart';
import '../../core/voice/oracly_voice_id.dart';
import '../../core/voice/oracly_tts_port.dart';
import '../../features/ai/production/oracly_ai_providers.dart';
import '../../core/experience/living_presence_tracker.dart';
import '../../core/experience/domain/models/experience_context.dart';
import '../../features/daily_ritual/services/daily_ritual_service.dart';
import '../../features/insights/services/personal_journey_service.dart';
import '../../core/services/first_session_service.dart';
import '../../core/first_session/first_session_intent.dart';
import '../../features/premium/models/personalization_models.dart';

// ── Infrastructure ─────────────────────────────────────────────────

final localStorageProvider = backend.localStorageProvider;
final secureStorageProvider = backend.secureStorageProvider;

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
  return MockPremiumRepository(
    ref.watch(localStorageProvider),
    secureStorage: ref.watch(backend.secureStorageProvider),
  );
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
  bool isAnalyticsEnabled() {
    final settings = ref.read(settingsProvider).valueOrNull;
    return settings?.analyticsEnabled ?? true;
  }

  return AnalyticsService(
    analytics: ProductAnalytics(
      sink: ref.watch(backend.firebaseAnalyticsProvider),
      logger: ref.watch(backend.analyticsLoggerProvider),
      isEnabled: isAnalyticsEnabled,
    ),
    quality: ref.watch(qualitySignalRecorderProvider),
  );
});

final crashTelemetryProvider = Provider<CrashTelemetryService>((ref) {
  bool isTelemetryEnabled() {
    final settings = ref.read(settingsProvider).valueOrNull;
    return settings?.analyticsEnabled ?? true;
  }

  return CrashTelemetryService(
    sink: ref.watch(backend.crashlyticsProvider),
    storage: ref.watch(localStorageProvider),
    isEnabled: isTelemetryEnabled,
  );
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
    ref.watch(premiumPurchasePortProvider),
    ref.watch(premiumEntitlementVerifierProvider),
    ref.watch(reviewAccessRepositoryProvider),
    ref.watch(reviewAccessServiceProvider),
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

/// Resolved UI locale from persisted settings (`tr` / `en` / `ru`).
///
/// Follows [settingsProvider] when loaded. While settings are still loading,
/// mirrors [AppLocale.resolvePreferred] (stored → device → tr) so a fresh
/// English/Russian device is never forced to Turkish for one frame.
final appLocaleProvider = Provider<Locale>((ref) {
  final async = ref.watch(settingsProvider);
  final loaded = async.maybeWhen(
    data: (s) => s.language,
    orElse: () => async.valueOrNull?.language,
  );
  if (loaded != null && loaded.trim().isNotEmpty) {
    return AppLocale.toLocale(loaded);
  }
  final storage = ref.watch(localStorageProvider);
  return AppLocale.toLocale(
    AppLocale.resolvePreferred(
      stored: storage.getString('settings_language'),
      device: AppLocale.readDeviceLocale(),
    ),
  );
});

/// Material [ThemeMode] — production v1 is Dark-only (see [AppAppearanceMode]).
final appThemeModeProvider = Provider<ThemeMode>((ref) {
  // Keep watching settings so flipping [lightModeUserSelectable] later rebuilds.
  ref.watch(settingsProvider);
  if (!AppAppearanceModeX.lightModeUserSelectable) {
    return AppAppearanceModeX.productionThemeMode;
  }
  final async = ref.watch(settingsProvider);
  final mode = async.maybeWhen(
    data: (s) => s.appearanceMode,
    orElse: () => async.valueOrNull?.appearanceMode,
  );
  return (mode ?? AppAppearanceMode.dark).themeMode;
});

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
final firebaseAuthReadyProvider = backend.firebaseAuthReadyProvider;
final sessionManagerProvider = backend.sessionManagerProvider;
final tokenManagerProvider = backend.tokenManagerProvider;
final syncQueueProvider = backend.syncQueueProvider;
final backgroundSyncProvider = backend.backgroundSyncProvider;
final dreamRepositoryProvider = backend.dreamRepositoryProvider;
final birthChartRepositoryProvider = backend.birthChartRepositoryProvider;
final astrologyRepositoryProvider = backend.astrologyRepositoryProvider;
final aiConversationRepositoryProvider =
    backend.aiConversationRepositoryProvider;
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

final intelligenceLayerServiceProvider = Provider<IntelligenceLayerService>((
  ref,
) {
  return IntelligenceLayerService(ref.watch(intelligenceRepositoryProvider));
});

final personalMemoryStoreProvider = Provider<PersonalMemoryStore>((ref) {
  return PersonalMemoryStore(ref.watch(localStorageProvider));
});

final personalMemoryServiceProvider = Provider<PersonalMemoryService>((ref) {
  return PersonalMemoryService(ref.watch(personalMemoryStoreProvider));
});

// ── Reflection engine (RC-010) ─────────────────────────────────────
// Logical heart of long-term understanding — not wired to UI in RC-010.

final reflectionEngineProvider = Provider<ReflectionEngine>((ref) {
  return const ReflectionEngine();
});

final reflectionEngineServiceProvider = Provider<ReflectionEngineService>((
  ref,
) {
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
      final remote = ref.watch(backend.remoteConfigServiceProvider);
      return ExperienceOrchestratorService(
        reflection: ref.watch(reflectionEngineServiceProvider),
        dailyRitual: ref.watch(dailyRitualServiceProvider),
        settings: ref.watch(settingsServiceProvider),
        premium: ref.watch(premiumServiceProvider),
        orchestrator: ref.watch(experienceOrchestratorProvider),
        remoteFeatureFlags: remote.snapshot.featureFlags,
      );
    });

final oraclySoundServiceProvider = Provider<OraclySoundService>((ref) {
  final service = OraclySoundService();
  ref.onDispose(service.dispose);
  return service;
});

final oraclyTtsProvider = Provider<OraclyTtsPort>((ref) {
  final tts = OraclyReplyTts(
    proxy: OraclyProxySpeech(ref.watch(aiTransportProvider)),
    device: OraclyDeviceTts(),
  );
  ref.onDispose(() {
    tts.dispose();
  });
  return tts;
});

final livingExperienceProvider = FutureProvider<ExperienceContext>((ref) {
  return ref.watch(experienceOrchestratorServiceProvider).decide();
});

final livingPresenceDaysProvider = FutureProvider<int?>((ref) async {
  final storage = ref.watch(localStorageProvider);
  return LivingPresenceTracker.daysAway(storage);
});

// ── First session (RC-012) ─────────────────────────────────────────

final firstSessionServiceProvider = Provider<FirstSessionService>((ref) {
  return FirstSessionService(ref.watch(historyRepositoryProvider));
});

final isFirstSessionProvider = FutureProvider<bool>((ref) {
  return ref.watch(firstSessionServiceProvider).isFirstSession();
});

/// Live Home/Tarot bridge — mirrors [FirstSessionIntent] for reactive UI.
final firstReadingPendingProvider = StateProvider<bool>((ref) {
  return FirstSessionIntent.isPending(ref.watch(localStorageProvider));
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
    final sound = ref.watch(oraclySoundServiceProvider);
    final loaded = await ref.watch(settingsServiceProvider).load();
    OraclyFeedbackGate.bind(
      service: sound,
      haptics: loaded.hapticEnabled,
      sounds: loaded.soundEnabled,
    );
    try {
      OraclyTtsGate.bind(
        service: ref.read(oraclyTtsProvider),
        enabled: loaded.voiceRepliesEnabled,
        style: loaded.aiPersonality,
        language: AppLocale.normalize(loaded.language),
        identity: OraclyVoiceId.parse(loaded.orVoiceId),
        speed: loaded.orSpeechSpeed,
      );
    } catch (_) {}
    try {
      await sound.setAtmosphere(loaded.atmosphereSign);
      await sound.syncAmbientEnabled(loaded.ambientMusicEnabled);
    } catch (_) {}
    return loaded;
  }

  Future<void> saveSettings(PersonalizationSettings settings) async {
    final prior = state.valueOrNull;
    final normalized = settings.copyWith(
      language: AppLocale.normalize(settings.language),
    );
    OraclyL10n.bind(normalized.language);
    await ref.read(settingsServiceProvider).save(normalized);
    state = AsyncData(normalized);
    if (prior != null && prior.language != normalized.language) {
      ref
          .read(analyticsServiceProvider)
          .logLanguageChanged(normalized.language);
    }
    OraclyFeedbackGate.bind(
      service: ref.read(oraclySoundServiceProvider),
      haptics: normalized.hapticEnabled,
      sounds: normalized.soundEnabled,
    );
    try {
      OraclyTtsGate.bind(
        service: ref.read(oraclyTtsProvider),
        enabled: normalized.voiceRepliesEnabled,
        style: normalized.aiPersonality,
        language: AppLocale.normalize(normalized.language),
        identity: OraclyVoiceId.parse(normalized.orVoiceId),
        speed: normalized.orSpeechSpeed,
      );
      if (!normalized.voiceRepliesEnabled) {
        // Never block Settings persistence on a slow/absent TTS engine.
        // ignore: unawaited_futures
        OraclyTtsGate.stop();
      }
    } catch (_) {}
    final sound = ref.read(oraclySoundServiceProvider);
    try {
      await sound.setAtmosphere(normalized.atmosphereSign);
      await sound.syncAmbientEnabled(normalized.ambientMusicEnabled);
    } catch (_) {}
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
