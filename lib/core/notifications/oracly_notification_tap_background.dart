/// Background isolate entry for notification taps.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'oracly_notification_tap_router.dart';

@pragma('vm:entry-point')
void oraclyNotificationTapBackground(NotificationResponse response) {
  OraclyNotificationTapRouter.offerPayload(response.payload);
}
