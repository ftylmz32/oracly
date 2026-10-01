/// In-memory sink — widget tests never hit a device plugin.
library;

import '../runtime/oracly_apply_outcome.dart';
import 'notification_permission.dart';
import 'oracly_notification_payload.dart';
import 'oracly_notification_port.dart';

class MemoryNotificationPort implements OraclyNotificationPort {
  OraclyNotificationPayload? scheduled;
  int cancelCount = 0;
  int scheduleCount = 0;
  bool permissionGranted = true;
  bool initialized = false;

  /// When set, overrides [permissionGranted] for both check and request.
  NotificationPermissionStatus? permissionOverride;

  /// Status a request moves to (e.g. notDetermined → granted). Null keeps
  /// the check result.
  NotificationPermissionStatus? statusAfterRequest;
  int permissionRequests = 0;

  /// Test hooks — simulate a real plugin/platform failure.
  bool scheduleShouldFail = false;
  bool cancelShouldFail = false;
  bool showShouldFail = false;

  final List<({String title, String body})> shown = [];

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async =>
      permissionOverride ??
      (permissionGranted
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied);

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    permissionRequests += 1;
    final next = statusAfterRequest;
    if (next != null) permissionOverride = next;
    return permissionStatus();
  }

  @override
  Future<OraclyApplyOutcome> scheduleDaily(
    OraclyNotificationPayload payload,
  ) async {
    if (scheduleShouldFail) return OraclyApplyOutcome.failure;
    scheduled = payload;
    scheduleCount += 1;
    return OraclyApplyOutcome.success;
  }

  @override
  Future<OraclyApplyOutcome> cancelAll() async {
    if (cancelShouldFail) return OraclyApplyOutcome.failure;
    scheduled = null;
    cancelCount += 1;
    return OraclyApplyOutcome.success;
  }

  @override
  Future<OraclyApplyOutcome> showTest({
    required String title,
    required String body,
  }) async {
    if (showShouldFail) return OraclyApplyOutcome.failure;
    shown.add((title: title, body: body));
    return OraclyApplyOutcome.success;
  }

  @override
  Future<void> captureColdStartLaunch() async {}
}
