/// Applies the daily invitation when Bildirimler is ON, cancels when OFF.
library;

import '../../features/personal_discovery/models/personal_discovery_profile.dart';
import '../../features/premium/models/personalization_models.dart';
import 'oracly_notification_planner.dart';
import 'oracly_notification_port.dart';

class OraclyNotificationCoordinator {
  OraclyNotificationCoordinator({
    required this.port,
    required this.loadProfile,
  });

  final OraclyNotificationPort port;
  final Future<PersonalDiscoveryProfile> Function() loadProfile;

  Future<void> sync(PersonalizationSettings settings) async {
    if (!settings.notificationsEnabled) {
      await port.cancelAll();
      return;
    }
    PersonalDiscoveryProfile profile = PersonalDiscoveryProfile.empty;
    try {
      profile = await loadProfile();
    } catch (_) {}
    final payload = OraclyNotificationPlanner.plan(
      enabled: true,
      profile: profile,
    );
    if (payload == null) {
      await port.cancelAll();
      return;
    }
    await port.scheduleDaily(payload);
  }
}
