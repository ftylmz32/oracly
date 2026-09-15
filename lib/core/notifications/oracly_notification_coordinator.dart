/// Applies the daily invitation when Bildirimler is ON, cancels when OFF.
library;

import '../../features/personal_discovery/models/personal_discovery_profile.dart';
import '../../features/premium/models/personalization_models.dart';
import '../runtime/oracly_apply_outcome.dart';
import 'oracly_notification_planner.dart';
import 'oracly_notification_port.dart';

class OraclyNotificationCoordinator {
  OraclyNotificationCoordinator({
    required this.port,
    required this.loadProfile,
  });

  final OraclyNotificationPort port;
  final Future<PersonalDiscoveryProfile> Function() loadProfile;

  /// Never throws — [port] reports a real scheduling/cancel failure as
  /// [OraclyApplyOutcome.failure] instead of letting it disappear.
  Future<OraclyApplyOutcome> sync(PersonalizationSettings settings) async {
    if (!settings.notificationsEnabled) {
      return port.cancelAll();
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
      return port.cancelAll();
    }
    return port.scheduleDaily(payload);
  }
}
