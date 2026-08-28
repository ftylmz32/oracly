/// Privacy Control Center — providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../services/memory_service.dart';
import '../../discovery_journal/providers/discovery_journal_providers.dart';
import '../../favorite_moments/providers/favorite_moments_providers.dart';
import '../../premium/models/personalization_models.dart';
import '../models/privacy_control_snapshot.dart';
import '../services/privacy_control_service.dart';
import '../services/privacy_control_snapshot_builder.dart';

final privacyControlServiceProvider = Provider<PrivacyControlService>((ref) {
  return PrivacyControlService(
    history: ref.watch(historyServiceProvider),
    favorites: ref.watch(favoriteMomentsServiceProvider),
    personalMemory: ref.watch(personalMemoryServiceProvider),
    birthCharts: ref.watch(birthChartRepositoryProvider),
    storage: ref.watch(localStorageProvider),
  );
});

final privacyControlSnapshotProvider =
    FutureProvider<PrivacyControlSnapshot>((ref) async {
  final profile = ref.watch(userProfileProvider).valueOrNull ??
      const UserProfileModel();
  final settings = ref.watch(settingsProvider).valueOrNull ??
      const PersonalizationSettings();
  final journal = await ref.watch(discoveryJournalEntriesProvider.future);
  final languageCode = ref.watch(appLocaleProvider).languageCode;

  return PrivacyControlSnapshotBuilder.build(
    favorites: ref.watch(favoriteMomentsServiceProvider),
    personalMemory: ref.watch(personalMemoryServiceProvider),
    legacyMemory: MemoryService(),
    profile: profile,
    settings: settings,
    discoveryCount: journal.length,
    languageCode: languageCode,
  );
});
