/// Clears device-local user data — account switch, deletion, and logout.
library;

import '../data/datasources/local_storage.dart';
import '../data/repositories/mock_premium_repository.dart';
import '../data/repositories/review_access_repository.dart';
import '../continuation/services/session_continuation_focus_store.dart';
import '../intelligence/data/intelligence_index_store.dart';
import '../intelligence/data/personal_memory_store.dart';
import '../reading_version/services/reading_version_store.dart';
import '../storage/secure_storage.dart';
import '../../features/astrology/data/astrology_preferences_store.dart';
import '../../features/coffee/data/coffee_reading_store.dart';
import '../../features/companion/services/first_reading_or_deepen.dart';
import '../../features/daily_rewards/services/daily_rewards_service.dart';
import '../../features/daily_ritual/services/card_of_the_day_store.dart';
import '../../features/dream/services/dream_attempt_store.dart';
import '../../features/favorite_moments/data/local_favorite_moments_repository.dart';
import '../../features/gems/data/paid_ai_operation_store.dart';
import '../../features/oracle_core/data/oracle_next_action_memory.dart';
import '../../features/palm/data/palm_reading_store.dart';
import '../../features/personal_discovery/data/daily_personal_observation_store.dart';
import '../../features/premium/data/soul_mate_result_store.dart';
import '../../features/premium/services/soul_mate_generation_session.dart';
import '../../features/reading_feedback/data/reading_feedback_store.dart';
import '../../features/reading_operation/services/reading_pending_operation_store.dart';
import '../../features/share_reopen/services/share_ownership_store.dart';
import '../../features/tarot/data/datasources/tarot_local_datasource.dart';
import '../../features/tarot/revisit/tarot_revisit_intent_store.dart';
import '../../features/privacy/services/discovery_owned_image_wipe.dart';
import '../../screens/profile/data/profile_photo_store.dart';
import 'user_local_data_wipe_keys.dart';
import 'user_local_data_wipe_result.dart';

abstract final class UserLocalDataWipe {
  UserLocalDataWipe._();

  /// Wipes every known ACCOUNT-SCOPED local store. Every step is
  /// attempted — best-effort PER ITEM, never per group — so one broken
  /// key/operation can never stop the rest from being attempted. The
  /// returned [UserLocalDataWipeResult] then reports honestly whether
  /// EVERY one of them actually succeeded: "try everything" and "tell the
  /// truth about what survived" are two separate guarantees, and a caller
  /// must not treat local ownership as transferred unless
  /// [UserLocalDataWipeResult.isComplete] is true. Device-scoped settings
  /// (`settings_*`) are intentionally untouched and never appear here.
  static Future<UserLocalDataWipeResult> run(
    LocalStorage storage, {
    required SecureStorage secureStorage,
  }) async {
    final failed = <String>[];

    Future<void> step(String label, Future<void> Function() action) async {
      try {
        await action();
      } catch (_) {
        failed.add(label);
      }
    }

    Future<void> stepKeys(Future<List<String>> Function() action) async {
      try {
        failed.addAll(await action());
      } catch (_) {
        // The batch call itself threw (not an individual key) — record it
        // without a specific key name rather than silently dropping it.
        failed.add('key_batch');
      }
    }

    // Owned-image FS cleanup (actual photo files, not a storage key) is
    // best-effort and intentionally fire-and-forget — it must never stall
    // account isolation when path_provider is unavailable (e.g. widget
    // tests), and there is no synchronous key identity to report here.
    // ignore: unawaited_futures
    DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImages(storage);
    await step(
      'or_reading_history',
      () => storage.setStringList('or_reading_history', const []),
    );
    await step(
      'dream_records',
      () => storage.setStringList('dream_records', const []),
    );
    await step(
      CoffeeReadingStore.key,
      () => storage.setStringList(CoffeeReadingStore.key, const []),
    );
    await step(
      PalmReadingStore.key,
      () => storage.setStringList(PalmReadingStore.key, const []),
    );
    await step(
      'astrology_history',
      () => storage.setStringList('astrology_history', const []),
    );
    await step(
      'ai_conversations',
      () => storage.setStringList('ai_conversations', const []),
    );
    await step('birth_chart_latest', () => storage.remove('birth_chart_latest'));
    await step(
      LocalFavoriteMomentsRepository.key,
      () => storage.remove(LocalFavoriteMomentsRepository.key),
    );
    await step(
      PersonalMemoryStore.key,
      () => storage.remove(PersonalMemoryStore.key),
    );
    await step(
      'oracly_connected_memory_v2',
      () => storage.remove('oracly_connected_memory_v2'),
    );
    await step(
      PersonalMemoryStore.userResetKey,
      () => storage.remove(PersonalMemoryStore.userResetKey),
    );
    await step(
      'discovery_surface_memory_v1',
      () => storage.remove('discovery_surface_memory_v1'),
    );
    await step('user_memories', () => storage.remove('user_memories'));
    // MemoryService's saved display name — was missing here, letting a new
    // account on the same device inherit the prior account's saved name.
    await step('user_name', () => storage.remove('user_name'));
    await stepKeys(() => _clearKeys(storage, UserLocalDataWipeKeys.profile));
    await step('profile_photo', () => ProfilePhotoStore.clear(storage));
    await step(
      'onboarding_setup_draft',
      () => storage.remove('onboarding_setup_draft'),
    );
    await step(
      FirstReadingOrDeepen.sessionKey,
      () => storage.remove(FirstReadingOrDeepen.sessionKey),
    );
    await step(
      FirstReadingOrDeepen.consumedKey,
      () => storage.remove(FirstReadingOrDeepen.consumedKey),
    );
    await step(
      DailyRewardsService.claimedKey,
      () => storage.remove(DailyRewardsService.claimedKey),
    );
    await step(
      AstrologyPreferencesStore.signKey,
      () => storage.remove(AstrologyPreferencesStore.signKey),
    );
    await step(
      CardOfTheDayStore.storageKey,
      () => storage.remove(CardOfTheDayStore.storageKey),
    );
    await step(
      IntelligenceIndexStore.key,
      () => storage.remove(IntelligenceIndexStore.key),
    );
    await step(
      OracleNextActionMemory.key,
      () => storage.remove(OracleNextActionMemory.key),
    );
    await step(
      DailyPersonalObservationStore.key,
      () => storage.remove(DailyPersonalObservationStore.key),
    );
    await step(
      ReadingFeedbackStore.key,
      () => storage.remove(ReadingFeedbackStore.key),
    );
    await step(
      TarotRevisitIntentStore.key,
      () => storage.remove(TarotRevisitIntentStore.key),
    );
    await step(
      'personal_insights_hidden',
      () => storage.remove('personal_insights_hidden'),
    );
    await step(
      'personal_insights_deleted',
      () => storage.remove('personal_insights_deleted'),
    );
    await step(
      ReadingVersionStore.key,
      () => storage.remove(ReadingVersionStore.key),
    );
    await step(
      SessionContinuationFocusStore.key,
      () => storage.remove(SessionContinuationFocusStore.key),
    );
    await step(
      ShareOwnershipStore.key,
      () => storage.remove(ShareOwnershipStore.key),
    );
    await step(
      'premium_local_state',
      () => MockPremiumRepository.clearPersistedLocalState(
        storage,
        secureStorage: secureStorage,
      ),
    );
    await step('secure_storage', () => secureStorage.deleteAll());
    await stepKeys(() => _clearKeys(storage, UserLocalDataWipeKeys.gems));
    await step('soul_mate_result', () => SoulMateResultStore.clear(storage));
    await step(
      'soul_mate_generation_session',
      () => SoulMateGenerationSessionStore.clear(storage),
    );
    await step(
      'soulmate_portrait_hashes',
      () => storage.remove('soulmate_portrait_hashes'),
    );
    await step(
      'soulmate_portrait_identity',
      () => storage.remove('soulmate_portrait_identity'),
    );
    await step(
      PaidAiOperationStore.key,
      () => storage.remove(PaidAiOperationStore.key),
    );
    await step(
      DreamAttemptStore.key,
      () => storage.remove(DreamAttemptStore.key),
    );
    await step(
      'coffee_v2_submission',
      () => storage.remove('coffee_v2_submission'),
    );
    await step(
      'coffee_v2_acknowledged_operation',
      () => storage.remove('coffee_v2_acknowledged_operation'),
    );
    await step(
      ReviewAccessRepository.grantedKey,
      () => storage.remove(ReviewAccessRepository.grantedKey),
    );
    await step(
      TarotLocalDataSource.historyKey,
      () => storage.setStringList(TarotLocalDataSource.historyKey, const []),
    );
    await step(
      TarotLocalDataSource.activeKey,
      () => storage.remove(TarotLocalDataSource.activeKey),
    );
    await step(
      'reading_pending_operations',
      () => ReadingPendingOperationStore.clearAll(storage),
    );
    await stepKeys(
      () => _clearPrefixed(storage, UserLocalDataWipeKeys.contentFavoritePrefix),
    );
    for (final prefix in UserLocalDataWipeKeys.prefixedUser) {
      await stepKeys(() => _clearPrefixed(storage, prefix));
    }

    return UserLocalDataWipeResult(failedOperations: failed);
  }

  /// Best-effort PER KEY, not per group: a single throwing `remove` must
  /// never stop the loop before it reaches the rest of [keys]. Returns the
  /// keys whose removal actually failed, so [run] can report them rather
  /// than silently absorbing them. Several account-scoped keys (e.g. the
  /// reading-count ledger ids/baseline) sit late in
  /// [UserLocalDataWipeKeys.profile] — if an earlier key's remove call
  /// threw and aborted the whole loop, every later key (including those)
  /// would have been silently left on disk for the next owner.
  static Future<List<String>> _clearKeys(
    LocalStorage storage,
    List<String> keys,
  ) async {
    final failed = <String>[];
    for (final key in keys) {
      try {
        await storage.remove(key);
      } catch (_) {
        failed.add(key);
      }
    }
    return failed;
  }

  /// Same per-key isolation and failure reporting as [_clearKeys], for a
  /// whole prefix set. The matching keys are snapshotted once up front so
  /// removing one key can't change which of the rest are still pending,
  /// and one key's failure never prevents the rest of the same prefix from
  /// being attempted.
  static Future<List<String>> _clearPrefixed(
    LocalStorage storage,
    String prefix,
  ) async {
    final failed = <String>[];
    final matching =
        storage.keys.where((k) => k.startsWith(prefix)).toList();
    for (final key in matching) {
      try {
        await storage.remove(key);
      } catch (_) {
        failed.add(key);
      }
    }
    return failed;
  }
}
