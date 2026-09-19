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

abstract final class UserLocalDataWipe {
  UserLocalDataWipe._();

  /// Wipes every known ACCOUNT_SCOPED local store. Continues after individual
  /// failures so one broken key cannot leave the rest of the identity intact.
  /// Device-scoped settings (`settings_*`) are intentionally untouched.
  static Future<void> run(
    LocalStorage storage, {
    required SecureStorage secureStorage,
  }) async {
    Future<void> step(Future<void> Function() action) async {
      try {
        await action();
      } catch (_) {}
    }

    // Owned-image FS cleanup is best-effort and must never stall account
    // isolation when path_provider is unavailable (e.g. widget tests).
    // ignore: unawaited_futures
    DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImages(storage);
    await step(() => storage.setStringList('or_reading_history', const []));
    await step(() => storage.setStringList('dream_records', const []));
    await step(() => storage.setStringList(CoffeeReadingStore.key, const []));
    await step(() => storage.setStringList(PalmReadingStore.key, const []));
    await step(() => storage.setStringList('astrology_history', const []));
    await step(() => storage.setStringList('ai_conversations', const []));
    await step(() => storage.remove('birth_chart_latest'));
    await step(() => storage.remove(LocalFavoriteMomentsRepository.key));
    await step(() => storage.remove(PersonalMemoryStore.key));
    await step(() => storage.remove('oracly_connected_memory_v2'));
    await step(() => storage.remove(PersonalMemoryStore.userResetKey));
    await step(() => storage.remove('discovery_surface_memory_v1'));
    await step(() => storage.remove('user_memories'));
    // MemoryService's saved display name — was missing here, letting a new
    // account on the same device inherit the prior account's saved name.
    await step(() => storage.remove('user_name'));
    await step(() => _clearKeys(storage, UserLocalDataWipeKeys.profile));
    await step(() => ProfilePhotoStore.clear(storage));
    await step(() => storage.remove('onboarding_setup_draft'));
    await step(() => storage.remove(FirstReadingOrDeepen.sessionKey));
    await step(() => storage.remove(FirstReadingOrDeepen.consumedKey));
    await step(() => storage.remove(DailyRewardsService.claimedKey));
    await step(() => storage.remove(AstrologyPreferencesStore.signKey));
    await step(() => storage.remove(CardOfTheDayStore.storageKey));
    await step(() => storage.remove(IntelligenceIndexStore.key));
    await step(() => storage.remove(OracleNextActionMemory.key));
    await step(() => storage.remove(DailyPersonalObservationStore.key));
    await step(() => storage.remove(ReadingFeedbackStore.key));
    await step(() => storage.remove(TarotRevisitIntentStore.key));
    await step(() => storage.remove('personal_insights_hidden'));
    await step(() => storage.remove('personal_insights_deleted'));
    await step(() => storage.remove(ReadingVersionStore.key));
    await step(() => storage.remove(SessionContinuationFocusStore.key));
    await step(() => storage.remove(ShareOwnershipStore.key));
    await step(
      () => MockPremiumRepository.clearPersistedLocalState(
        storage,
        secureStorage: secureStorage,
      ),
    );
    await step(() => secureStorage.deleteAll());
    await step(() => _clearKeys(storage, UserLocalDataWipeKeys.gems));
    await step(() => SoulMateResultStore.clear(storage));
    await step(() => SoulMateGenerationSessionStore.clear(storage));
    await step(() => storage.remove('soulmate_portrait_hashes'));
    await step(() => storage.remove('soulmate_portrait_identity'));
    await step(() => storage.remove(PaidAiOperationStore.key));
    await step(() => storage.remove(DreamAttemptStore.key));
    await step(() => storage.remove('coffee_v2_submission'));
    await step(() => storage.remove('coffee_v2_acknowledged_operation'));
    await step(() => storage.remove(ReviewAccessRepository.grantedKey));
    await step(
      () => storage.setStringList(TarotLocalDataSource.historyKey, const []),
    );
    await step(() => storage.remove(TarotLocalDataSource.activeKey));
    await step(() => ReadingPendingOperationStore.clearAll(storage));
    await step(
      () => _clearPrefixed(storage, UserLocalDataWipeKeys.contentFavoritePrefix),
    );
    await step(() => _clearPrefixed(storage, 'content_favorites_'));
    for (final prefix in UserLocalDataWipeKeys.prefixedUser) {
      await step(() => _clearPrefixed(storage, prefix));
    }
  }

  static Future<void> _clearKeys(LocalStorage storage, List<String> keys) async {
    for (final key in keys) {
      await storage.remove(key);
    }
  }

  static Future<void> _clearPrefixed(LocalStorage storage, String prefix) async {
    for (final key
        in storage.keys.where((k) => k.startsWith(prefix)).toList()) {
      await storage.remove(key);
    }
  }
}
