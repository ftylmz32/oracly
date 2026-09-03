/// Clears device-local user data — used on account switch only.
library;

import '../data/datasources/local_storage.dart';
import '../data/repositories/mock_premium_repository.dart';
import '../intelligence/data/intelligence_index_store.dart';
import '../intelligence/data/personal_memory_store.dart';
import '../storage/secure_storage.dart';
import '../../features/astrology/data/astrology_preferences_store.dart';
import '../../features/coffee/data/coffee_reading_store.dart';
import '../../features/companion/services/first_reading_or_deepen.dart';
import '../../features/daily_rewards/services/daily_rewards_service.dart';
import '../../features/daily_ritual/services/card_of_the_day_store.dart';
import '../../features/favorite_moments/data/local_favorite_moments_repository.dart';
import '../../features/gems/data/gem_wallet_store.dart';
import '../../features/gems/data/paid_ai_operation_store.dart';
import '../../features/gems/services/gem_starter_grant.dart';
import '../../features/palm/data/palm_reading_store.dart';
import '../../features/premium/data/soul_mate_result_store.dart';
import '../../features/tarot/data/datasources/tarot_local_datasource.dart';
import '../../features/privacy/services/discovery_owned_image_wipe.dart';
import '../../screens/profile/data/profile_photo_store.dart';

abstract final class UserLocalDataWipe {
  UserLocalDataWipe._();

  static Future<void> run(
    LocalStorage storage, {
    required SecureStorage secureStorage,
  }) async {
    await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImages(storage);
    await storage.setStringList('or_reading_history', const []);
    await storage.setStringList('dream_records', const []);
    await storage.setStringList(CoffeeReadingStore.key, const []);
    await storage.setStringList(PalmReadingStore.key, const []);
    await storage.setStringList('astrology_history', const []);
    await storage.setStringList('ai_conversations', const []);
    await storage.remove('birth_chart_latest');
    await storage.remove(LocalFavoriteMomentsRepository.key);
    await storage.remove(PersonalMemoryStore.key);
    await storage.remove(PersonalMemoryStore.userResetKey);
    await storage.remove('discovery_surface_memory_v1');
    await storage.remove('user_memories');
    await storage.remove('user_name');
    await storage.remove('profile_name');
    await storage.remove('profile_job');
    await storage.remove('profile_interests');
    await storage.remove('profile_goals');
    await storage.remove('profile_streak');
    await storage.remove('profile_readings');
    await storage.remove('profile_spiritual');
    await storage.remove('profile_favorite_deck');
    await storage.remove('profile_achievements');
    await ProfilePhotoStore.clear(storage);
    await storage.remove('onboarding_setup_draft');
    await storage.remove(FirstReadingOrDeepen.sessionKey);
    await storage.remove(FirstReadingOrDeepen.consumedKey);
    await storage.remove(DailyRewardsService.claimedKey);
    await storage.remove(AstrologyPreferencesStore.signKey);
    await storage.remove(CardOfTheDayStore.storageKey);
    await storage.remove(IntelligenceIndexStore.key);
    await MockPremiumRepository.clearPersistedLocalState(
      storage,
      secureStorage: secureStorage,
    );
    await secureStorage.deleteAll();
    await storage.remove(GemWalletStore.balanceKey);
    await storage.remove(GemWalletStore.txKey);
    await storage.remove(GemStarterGrant.flagKey);
    await storage.remove('tarot_gem_charged_sessions');
    await storage.remove('coffee_gem_charged');
    await storage.remove('dream_gem_charged');
    await storage.remove('palm_gem_charged');
    await storage.remove('soulmate_gem_charged');
    await SoulMateResultStore.clear(storage);
    await storage.remove(PaidAiOperationStore.key);
    await storage.setStringList(TarotLocalDataSource.historyKey, const []);
    await storage.remove(TarotLocalDataSource.activeKey);
    for (final domain in _contentFavoriteDomains) {
      await storage.remove('content_favorites_$domain');
    }
    for (final key in storage.keys
        .where((k) => k.startsWith('content_favorites_'))
        .toList()) {
      await storage.remove(key);
    }
    for (final prefix in _prefixedUserKeys) {
      for (final key
          in storage.keys.where((k) => k.startsWith(prefix)).toList()) {
        await storage.remove(key);
      }
    }
  }

  static const _prefixedUserKeys = [
    'daily_ritual_',
    'or_tarot_interpretation_',
    'daily_return_',
  ];

  static const _contentFavoriteDomains = [
    'tarot',
    'dream',
    'astrology',
    'daily_energy',
    'oracle',
  ];
}
