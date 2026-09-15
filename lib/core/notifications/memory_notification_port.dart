/// In-memory sink — widget tests never hit a device plugin.
library;

import '../runtime/oracly_apply_outcome.dart';
import 'oracly_notification_payload.dart';
import 'oracly_notification_port.dart';

class MemoryNotificationPort implements OraclyNotificationPort {
  OraclyNotificationPayload? scheduled;
  int cancelCount = 0;
  int scheduleCount = 0;
  bool permissionGranted = true;
  bool initialized = false;

  /// Test hooks — simulate a real plugin/platform failure.
  bool scheduleShouldFail = false;
  bool cancelShouldFail = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<bool> requestPermission() async => permissionGranted;

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
  Future<void> captureColdStartLaunch() async {}
}
