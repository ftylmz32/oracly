/// In-memory sink — widget tests never hit a device plugin.
library;

import 'oracly_notification_payload.dart';
import 'oracly_notification_port.dart';

class MemoryNotificationPort implements OraclyNotificationPort {
  OraclyNotificationPayload? scheduled;
  int cancelCount = 0;
  bool permissionGranted = true;
  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> scheduleDaily(OraclyNotificationPayload payload) async {
    scheduled = payload;
  }

  @override
  Future<void> cancelAll() async {
    scheduled = null;
    cancelCount += 1;
  }

  @override
  Future<void> captureColdStartLaunch() async {}
}
