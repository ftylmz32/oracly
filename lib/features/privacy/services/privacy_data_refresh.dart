/// Invalidate all derived state after privacy actions — no ghost data.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/revisit/providers/discovery_revisit_provider.dart';
import '../../../screens/profile/data/profile_photo_store.dart';
import '../../companion/providers/companion_providers.dart';
import '../../favorite_moments/providers/favorite_moments_providers.dart';
import '../../gems/providers/gem_providers.dart';
import '../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../personal_discovery/services/personal_discovery_refresh.dart';

abstract final class PrivacyDataRefresh {
  PrivacyDataRefresh._();

  static void afterDiscoveryHistoryClear(WidgetRef ref) {
    ref.invalidate(readingHistoryProvider);
    PersonalDiscoveryRefresh.invalidate(ref);
    ref.invalidate(discoveryRevisitOfferProvider);
    ref.invalidate(livingExperienceProvider);
    _reloadCompanion(ref);
  }

  static void afterFavoritesClear(WidgetRef ref) {
    ref.invalidate(favoriteMomentsProvider);
  }

  static void afterMemoryReset(WidgetRef ref) {
    ref.invalidate(discoveryRevisitOfferProvider);
    ref.invalidate(discoverySurfaceMemoryProvider);
    _reloadCompanion(ref);
  }

  /// Full local wipe on auth account switch — no ghost profile/history/gems.
  static void afterAccountSwitch(WidgetRef ref) {
    ref.invalidate(userProfileProvider);
    ref.invalidate(readingHistoryProvider);
    ref.invalidate(settingsProvider);
    ref.invalidate(premiumActiveProvider);
    PersonalDiscoveryRefresh.invalidate(ref);
    ref.invalidate(discoveryRevisitOfferProvider);
    ref.invalidate(discoverySurfaceMemoryProvider);
    ref.invalidate(favoriteMomentsProvider);
    ref.invalidate(livingExperienceProvider);
    ref.invalidate(gemWalletProvider);
    ref.invalidate(gemStarterGrantProvider);
    ref.read(profilePhotoEpochProvider.notifier).state++;
    _reloadCompanion(ref);
  }

  static void _reloadCompanion(WidgetRef ref) {
    ref.read(companionControllerProvider).reloadFromStorage();
  }
}
