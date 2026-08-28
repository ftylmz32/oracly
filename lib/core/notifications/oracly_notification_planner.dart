/// Picks at most one daily invitation from real, recent evidence.
library;

import '../remote_config/remote_config_runtime.dart';
import '../modules/oracly_feature_availability.dart';
import '../modules/oracly_feature_id.dart';
import '../modules/oracly_feature_registry.dart';
import '../../features/personal_discovery/models/personal_discovery_profile.dart';
import 'oracly_notification_copy.dart';
import 'oracly_notification_kind.dart';
import 'oracly_notification_payload.dart';
import 'oracly_notification_privacy.dart';

abstract final class OraclyNotificationPlanner {
  OraclyNotificationPlanner._();

  static const orRecentDays = 7;
  static const themeRecentDays = 30;
  static int get dailyHour => RemoteConfigRuntime.snapshot.notificationDailyHour;

  static OraclyNotificationPayload? plan({
    required bool enabled,
    required PersonalDiscoveryProfile profile,
    DateTime? now,
    Set<OraclyFeatureId>? offered,
  }) {
    if (!enabled) return null;
    final clock = now ?? DateTime.now();
    final live = offered ?? _live();
    final discovery = _discovery(profile, clock, live);
    if (discovery != null) return discovery;
    final or = _or(profile, clock, live);
    if (or != null) return or;
    return _daily(live);
  }

  static OraclyNotificationPayload? _discovery(
    PersonalDiscoveryProfile profile,
    DateTime now,
    Set<OraclyFeatureId> live,
  ) {
    if (!live.contains(OraclyFeatureId.discoveryJournal)) return null;
    for (final insight in profile.crossInsights) {
      final days = now.difference(insight.lastObserved).inDays;
      if (days < 0 || days > themeRecentDays) continue;
      if (insight.discoveryCount < 2) continue;
      final theme = OraclyNotificationPrivacy.publicThemeLabel(insight.theme);
      final payload = _safe(
        OraclyNotificationKind.discovery,
        theme: theme,
      );
      if (payload != null) return payload;
    }
    return null;
  }

  static OraclyNotificationPayload? _or(
    PersonalDiscoveryProfile profile,
    DateTime now,
    Set<OraclyFeatureId> live,
  ) {
    if (!live.contains(OraclyFeatureId.aiChat)) return null;
    DateTime? last;
    for (final item in profile.sourceActivity) {
      if (item.source != 'reflection') continue;
      last = item.lastAt;
    }
    if (last == null) return null;
    final days = now.difference(last).inDays;
    if (days < 0 || days > orRecentDays) return null;
    return _safe(OraclyNotificationKind.companion);
  }

  static OraclyNotificationPayload? _daily(Set<OraclyFeatureId> live) {
    if (!live.contains(OraclyFeatureId.dailyMessage)) return null;
    return _safe(OraclyNotificationKind.daily);
  }

  static OraclyNotificationPayload? _safe(
    OraclyNotificationKind kind, {
    String? theme,
  }) {
    final body = OraclyNotificationCopy.body(kind, theme: theme);
    if (!OraclyNotificationPrivacy.isSafePreview(body)) {
      if (kind == OraclyNotificationKind.discovery && theme != null) {
        return _safe(kind);
      }
      return null;
    }
    return OraclyNotificationPayload(
      kind: kind,
      title: OraclyNotificationCopy.title,
      body: body,
    );
  }

  static Set<OraclyFeatureId> _live() {
    return {
      for (final module in OraclyFeatureRegistry.all)
        if (module.availability != OraclyFeatureAvailability.reserved)
          module.id,
    };
  }
}
