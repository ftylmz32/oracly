/// Clears device-local user data — used on account switch only.
library;

import '../data/datasources/local_storage.dart';
import '../intelligence/data/personal_memory_store.dart';
import '../../features/coffee/data/coffee_reading_store.dart';
import '../../features/favorite_moments/data/local_favorite_moments_repository.dart';
import '../../features/gems/data/gem_wallet_store.dart';
import '../../features/gems/data/paid_ai_operation_store.dart';
import '../../features/gems/services/gem_starter_grant.dart';
import '../../features/palm/data/palm_reading_store.dart';
import '../../features/premium/data/soul_mate_result_store.dart';
import '../../features/tarot/data/datasources/tarot_local_datasource.dart';

abstract final class UserLocalDataWipe {
  UserLocalDataWipe._();

  static Future<void> run(LocalStorage storage) async {
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
    await storage.remove('profile_photo_path');
    await storage.remove('or_premium_active');
    await storage.remove('or_premium_plan');
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
  }

  static const _contentFavoriteDomains = [
    'tarot',
    'dream',
    'astrology',
    'daily_energy',
    'oracle',
  ];
}
