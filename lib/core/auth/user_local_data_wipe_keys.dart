/// Key lists for [UserLocalDataWipe] — keep wipe orchestration under 150 lines.
library;

import '../../features/gems/data/gem_wallet_store.dart';
import '../../features/gems/services/gem_starter_grant.dart';

abstract final class UserLocalDataWipeKeys {
  UserLocalDataWipeKeys._();

  static const profile = [
    'user_name',
    'profile_name',
    'profile_job',
    'profile_interests',
    'profile_goals',
    'profile_streak',
    'profile_readings',
    'profile_spiritual',
    'profile_favorite_deck',
    'profile_achievements',
  ];

  static const gems = [
    GemWalletStore.balanceKey,
    GemWalletStore.serverBalanceCacheKey,
    GemWalletStore.serverBalanceOwnerKey,
    GemWalletStore.txKey,
    GemStarterGrant.flagKey,
    'tarot_gem_charged_sessions',
    'coffee_gem_charged',
    'dream_gem_charged',
    'palm_gem_charged',
    'soulmate_gem_charged',
  ];

  static const contentFavoritePrefix = 'content_favorites_';

  static const prefixedUser = [
    'daily_ritual_',
    'or_tarot_interpretation_',
    'daily_return_',
  ];
}
