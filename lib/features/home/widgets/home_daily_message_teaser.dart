/// Compact Home Today teaser - existing Daily Message loop, not a second card.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/providers/backend_providers.dart' as backend;
import '../../../core/navigation/oracly_navigation_service.dart';
import 'home_daily_message_teaser_body.dart';
import '../../daily_message/data/daily_return_store.dart';
import '../../daily_message/models/daily_message.dart';
import '../../daily_message/services/daily_message_session.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../premium/models/personalization_models.dart';

/// Thin teaser under Today ritual - opens Daily Message.
class HomeDailyMessageTeaser extends ConsumerStatefulWidget {
  const HomeDailyMessageTeaser({super.key});

  @override
  ConsumerState<HomeDailyMessageTeaser> createState() =>
      _HomeDailyMessageTeaserState();
}

class _HomeDailyMessageTeaserState
    extends ConsumerState<HomeDailyMessageTeaser> {
  bool _recorded = false;
  int _boundEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;

  DailyMessage? _resolveOrNull({
    required String? profileName,
    required PersonalDiscoveryProfile? discovery,
    required AiPersonality? personality,
  }) {
    try {
      final storage = ref.read(localStorageProvider);
      return DailyMessageSession.resolve(
        store: DailyReturnStore(storage),
        day: DateTime.now(),
        profileName: profileName,
        discovery: discovery,
        recent: ref.read(discoverySurfaceMemoryProvider).all(),
        personality: personality,
      );
    } catch (_) {
      return null;
    }
  }

  void _persistOnce(DailyMessage message) {
    if (_recorded) return;
    _recorded = true;
    final epoch = _boundEpoch;
    DailyMessageSession.persistAfterFrame(
      ownerEpoch: epoch,
      isMounted: () => mounted,
      write: () async {
        try {
          final storage = ref.read(localStorageProvider);
          await DailyMessageSession.persist(
            store: DailyReturnStore(storage),
            memory: ref.read(discoverySurfaceMemoryProvider),
            message: message,
            ownerEpoch: epoch,
          );
        } catch (_) {}
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final epoch = ref.watch(backend.localDataOwnerEpochProvider);
    if (_boundEpoch != epoch) {
      _boundEpoch = epoch;
      _recorded = false;
    }
    final profileAsync = ref.watch(userProfileProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final discoveryAsync = ref.watch(personalDiscoveryProfileProvider);
    if (profileAsync.isLoading ||
        settingsAsync.isLoading ||
        discoveryAsync.isLoading ||
        profileAsync.hasError ||
        settingsAsync.hasError ||
        discoveryAsync.hasError) {
      return const SizedBox.shrink();
    }
    final message = _resolveOrNull(
      profileName: profileAsync.valueOrNull?.name,
      discovery: discoveryAsync.valueOrNull,
      personality: settingsAsync.valueOrNull?.aiPersonality,
    );
    final text = message?.text.trim() ?? '';
    if (message == null || text.isEmpty) {
      return const SizedBox.shrink();
    }
    _persistOnce(message);

    return HomeDailyMessageTeaserBody(
      text: text,
      onTap: () => OraclyNavigationService.openDailyMessage(context),
    );
  }
}
