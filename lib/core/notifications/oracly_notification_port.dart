/// Local notification sink. Tests use a memory implementation.
library;

import 'oracly_notification_payload.dart';

abstract class OraclyNotificationPort {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> scheduleDaily(OraclyNotificationPayload payload);

  Future<void> cancelAll();
}
