/// OR-1130 — Backend infrastructure Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_runtime.dart';
import '../auth/auth_service.dart';
import '../auth/auth_service_selection.dart';
import '../auth/firebase/firebase_auth_bootstrap.dart';
import '../auth/firebase/firebase_auth_gateway.dart';
import '../auth/firebase/firebase_id_token_manager.dart';
import '../auth/firebase/live_firebase_auth_gateway.dart';
import '../auth/secure_token_manager.dart';
import '../auth/session_manager.dart';
import '../auth/token_manager.dart';
import '../data/datasources/local_storage.dart';
import '../data/repositories/local_ai_conversation_repository.dart';
import '../data/repositories/local_birth_chart_repository.dart';
import '../data/repositories/local_astrology_repository.dart';
import '../data/repositories/local_dream_repository.dart';
import '../domain/repositories/ai_conversation_repository.dart';
import '../domain/repositories/birth_chart_repository.dart';
import '../domain/repositories/astrology_repository.dart';
import '../domain/repositories/dream_repository.dart';
import '../logging/analytics_logger.dart';
import '../logging/crash_logger.dart';
import '../logging/logger.dart';
import '../logging/performance_logger.dart';
import '../monitoring/crashlytics.dart';
import '../monitoring/firebase_analytics.dart';
import '../monitoring/performance_monitor.dart';
import '../remote_config/remote_config_pending_store.dart';
import '../remote_config/remote_config_port.dart';
import '../remote_config/remote_config_service.dart';
import '../experiments/experiment_service.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../network/retry_interceptor.dart';
import '../security/api_key_provider.dart';
import '../security/certificate_pinning.dart';
import '../storage/cache_storage.dart';
import '../storage/local_cache_storage.dart';
import '../storage/platform_secure_storage.dart';
import '../storage/secure_storage.dart';
import '../sync/background_sync.dart';
import '../sync/conflict_resolver.dart';
import '../sync/offline_cache.dart';
import '../sync/retry_queue.dart';
import '../sync/sync_queue.dart';

// ── Security ─────────────────────────────────────────────────────

final apiKeyProvider = Provider<ApiKeyProvider>((ref) {
  return const EnvApiKeyProvider();
});

final certificatePinningProvider = Provider<CertificatePinningConfig>((ref) {
  return const EnvironmentCertificatePinning();
});

// ── Storage ──────────────────────────────────────────────────────

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return PlatformSecureStorage();
});

final cacheStorageProvider = Provider<CacheStorage>((ref) {
  return LocalCacheStorage(ref.watch(localStorageProvider));
});

final offlineCacheProvider = Provider<OfflineCache>((ref) {
  return OfflineCacheManager(ref.watch(cacheStorageProvider));
});

// ── Auth ─────────────────────────────────────────────────────────

final firebaseAuthReadyProvider = Provider<bool>((ref) {
  final notifier = FirebaseAuthBootstrap.ready;
  void listener() => ref.invalidateSelf();
  notifier.addListener(listener);
  ref.onDispose(() => notifier.removeListener(listener));
  return notifier.value || FirebaseAuthBootstrap.isReady;
});

final firebaseAuthGatewayProvider = Provider<FirebaseAuthGateway?>((ref) {
  final ready = ref.watch(firebaseAuthReadyProvider);
  if (!ready) return null;
  return LiveFirebaseAuthGateway();
});

final tokenManagerProvider = Provider<TokenManager>((ref) {
  final stored = SecureTokenManager(ref.watch(secureStorageProvider));
  final gateway = ref.watch(firebaseAuthGatewayProvider);
  if (gateway != null && gateway.isInitialized) {
    return FirebaseIdTokenManager(gateway, fallback: stored);
  }
  return stored;
});

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return InMemorySessionManager(ref.watch(tokenManagerProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  final ready = ref.watch(firebaseAuthReadyProvider);
  return AuthServiceSelection.create(
    productionLike: AuthRuntime.isProductionLike,
    firebaseReady: ready,
    gateway: ref.watch(firebaseAuthGatewayProvider),
    tokens: ref.watch(tokenManagerProvider),
    sessions: ref.watch(sessionManagerProvider),
    storage: ref.watch(localStorageProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

// ── Network ──────────────────────────────────────────────────────

final retryInterceptorProvider = Provider<RetryInterceptor>((ref) {
  return RetryInterceptor();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);
  return ApiClient(
    interceptors: [
      AuthInterceptor(tokenManager),
      ref.watch(retryInterceptorProvider),
    ],
    retryInterceptor: ref.watch(retryInterceptorProvider),
    logger: Logger('ApiClient'),
  );
});

// ── Sync ─────────────────────────────────────────────────────────

final syncQueueProvider = Provider<SyncQueue>((ref) {
  return InMemorySyncQueue();
});

final retryQueueProvider = Provider<RetryQueue>((ref) {
  return ExponentialRetryQueue(ref.watch(syncQueueProvider));
});

final conflictResolverProvider = Provider<ConflictResolver>((ref) {
  return TimestampConflictResolver();
});

final backgroundSyncProvider = Provider<BackgroundSyncService>((ref) {
  return BackgroundSyncCoordinator(
    syncQueue: ref.watch(syncQueueProvider),
    retryQueue: ref.watch(retryQueueProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});

// ── Logging & monitoring ─────────────────────────────────────────

final loggerProvider = Provider.family<Logger, String>((ref, tag) {
  return Logger(tag);
});

final crashLoggerProvider = Provider<CrashLogger>((ref) {
  return ConsoleCrashLogger();
});

final analyticsLoggerProvider = Provider<AnalyticsLogger>((ref) {
  return const ConsoleAnalyticsLogger();
});

final performanceLoggerProvider = Provider<PerformanceLogger>((ref) {
  return ConsolePerformanceLogger();
});

final firebaseAnalyticsProvider = Provider<FirebaseAnalyticsService>((ref) {
  return NoOpFirebaseAnalytics(logger: ref.watch(analyticsLoggerProvider));
});

final crashlyticsProvider = Provider<CrashlyticsService>((ref) {
  return NoOpCrashlyticsService(logger: ref.watch(crashLoggerProvider));
});

final remoteConfigPortProvider = Provider<RemoteConfigPort>((ref) {
  return const LocalRemoteConfigPort();
});

final remoteConfigPendingStoreProvider = Provider<RemoteConfigPendingStore>((ref) {
  return RemoteConfigPendingStore(ref.watch(localStorageProvider));
});

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService(
    port: ref.watch(remoteConfigPortProvider),
    pendingStore: ref.watch(remoteConfigPendingStoreProvider),
  );
});

final experimentServiceProvider = Provider<ExperimentService>((ref) {
  return ExperimentService(storage: ref.watch(localStorageProvider));
});

final performanceMonitorProvider = Provider<PerformanceMonitoringService>((ref) {
  return NoOpPerformanceMonitoring(logger: ref.watch(performanceLoggerProvider));
});

// ── Extended repositories ────────────────────────────────────────

final dreamRepositoryProvider = Provider<DreamRepository>((ref) {
  return LocalDreamRepository(ref.watch(localStorageProvider));
});

final birthChartRepositoryProvider = Provider<BirthChartRepository>((ref) {
  return LocalBirthChartRepository(ref.watch(localStorageProvider));
});

final astrologyRepositoryProvider = Provider<AstrologyRepository>((ref) {
  return LocalAstrologyRepository(ref.watch(localStorageProvider));
});

final aiConversationRepositoryProvider = Provider<AiConversationRepository>((ref) {
  return LocalAiConversationRepository(ref.watch(localStorageProvider));
});

/// Shared with [app_providers.dart] — must be overridden at bootstrap.
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw StateError('localStorageProvider must be overridden at bootstrap');
});
