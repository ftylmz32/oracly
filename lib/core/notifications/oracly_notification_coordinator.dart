/// Applies the daily invitation when Bildirimler is ON, cancels when OFF.
library;

import '../../features/personal_discovery/models/personal_discovery_profile.dart';
import '../../features/premium/models/personalization_models.dart';
import '../runtime/oracly_apply_outcome.dart';
import 'notification_delivery_state.dart';
import 'notification_permission.dart';
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
  ///
  /// Success means the daily invitation is really deliverable: preference
  /// on, OS permission allows delivery, and the OS confirmed the slot. When
  /// the OS blocks delivery the slot is still kept (so it works the moment
  /// permission returns) but the outcome is failure, never a silent success.
  Future<OraclyApplyOutcome> sync(PersonalizationSettings settings) async {
    NotificationDeliveryStatus.recordPreference(settings.notificationsEnabled);
    if (!settings.notificationsEnabled) {
      return _cancel(LocalScheduleState.disabled);
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
      return _cancel(LocalScheduleState.disabled);
    }

    final permission = await port.permissionStatus();
    final scheduled = await port.scheduleDaily(payload);
    // Same OS read the port may already have recorded; recording it here
    // keeps the permission domain correct for every port implementation.
    NotificationDeliveryStatus.recordPermission(permission);
    if (scheduled.isFailure) {
      // Keeps a more precise current category (e.g. scheduleNotConfirmed).
      NotificationDeliveryStatus.recordSchedule(LocalScheduleState.failed);
      return OraclyApplyOutcome.failure;
    }
    NotificationDeliveryStatus.recordSchedule(LocalScheduleState.scheduled);
    return permission.canDeliver
        ? OraclyApplyOutcome.success
        : OraclyApplyOutcome.failure;
  }

  Future<OraclyApplyOutcome> _cancel(LocalScheduleState after) async {
    final outcome = await port.cancelAll();
    if (outcome.isFailure) {
      NotificationDeliveryStatus.recordSchedule(
        LocalScheduleState.failed,
        failure: NotificationFailureCategory.cancelFailed,
      );
    } else {
      NotificationDeliveryStatus.recordSchedule(after);
    }
    return outcome;
  }
}
