/// Resolves one daily snapshot from cache or real discovery evidence.
library;

import 'package:flutter/widgets.dart';

import '../../../core/auth/user_local_data_isolation.dart';
import '../../premium/models/personalization_models.dart';
import '../../personal_discovery/data/discovery_surface_memory.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../../personal_discovery/models/personal_insight.dart';
import '../../personal_discovery/models/surfaced_theme_record.dart';
import '../../personal_discovery/providers/personal_discovery_providers.dart';
import '../data/daily_return_store.dart';
import 'daily_message_service.dart';

abstract final class DailyMessageSession {
  DailyMessageSession._();

  static DailyMessage resolve({
    required DailyReturnStore store,
    required DateTime day,
    String? profileName,
    PersonalDiscoveryProfile? discovery,
    List<SurfacedThemeRecord> recent = const [],
    AiPersonality? personality,
  }) {
    final cached = store.readToday(day);
    if (cached != null) return cached;
    final previous = store.readPrevious(day);
    final insights = discovery == null
        ? const <PersonalInsight>[]
        : discoveryInsightsFor(discovery, recent, surface: 'daily', day: day);
    final sign = discovery?.zodiacSign?.labelTr;
    return DailyMessageService.forDay(
      day: day,
      profileName: profileName,
      insight: insights.isEmpty ? null : insights.first,
      themes: [
        for (final item in insights) item.theme,
        ...?discovery?.recurringThemes,
      ],
      previousTheme: previous?.theme,
      previousText: previous?.text,
      previousAction: previous?.action,
      recentTexts: store.historyTexts(),
      sunSign: sign,
      personality: personality ?? discovery?.preferredOrStyle,
      hasDiscoveries: discovery?.hasHistory ?? false,
    );
  }

  static Future<void> persist({
    required DailyReturnStore store,
    required DiscoverySurfaceMemory memory,
    required DailyMessage message,
    int? ownerEpoch,
  }) async {
    final epoch = ownerEpoch ?? UserLocalDataIsolation.accountSwitchEpoch.value;
    if (!_sameOwner(epoch)) return;
    final already = store.readToday(message.day);
    if (!_sameOwner(epoch)) return;
    await store.commit(message);
    if (!_sameOwner(epoch)) return;
    if (already != null) return;
    final theme = message.theme;
    if (theme == null || theme.isEmpty) return;
    if (!_sameOwner(epoch)) return;
    await memory.record(
      SurfacedThemeRecord(theme: theme, surface: 'daily', at: message.day),
    );
  }

  static bool _sameOwner(int epoch) =>
      UserLocalDataIsolation.accountSwitchEpoch.value == epoch;

  /// Runs [write] only if the account-switch epoch is still [ownerEpoch].
  static void persistAfterFrame({
    required int ownerEpoch,
    required bool Function() isMounted,
    required Future<void> Function() write,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted()) return;
      if (!_sameOwner(ownerEpoch)) return;
      write();
    });
  }
}
