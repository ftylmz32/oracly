/// User-triggered "send a test notification" from Settings.
///
/// Exists only behind an explicit Settings tap — never scheduled, never sent
/// automatically. Reports exactly why nothing could be shown instead of
/// claiming success.
library;

import '../runtime/oracly_apply_outcome.dart';
import 'notification_delivery_state.dart';
import 'notification_permission.dart';
import 'oracly_notification_port.dart';

enum NotificationTestResult {
  /// The OS accepted the notification for display.
  sent,
  permissionDenied,
  permissionPermanentlyDenied,
  permissionUnavailable,
  deliveryFailed,
}

class OraclyNotificationTestSender {
  OraclyNotificationTestSender(this.port);

  final OraclyNotificationPort port;

  Future<NotificationTestResult> send({
    required String title,
    required String body,
  }) async {
    var status = await port.permissionStatus();
    if (status == NotificationPermissionStatus.notDetermined ||
        status == NotificationPermissionStatus.denied) {
      // Only prompts where the OS still allows it (first ask on iOS,
      // not-yet-permanent refusal on Android).
      status = await port.requestPermission();
    }
    if (!status.canDeliver) {
      return switch (status) {
        NotificationPermissionStatus.permanentlyDenied =>
          NotificationTestResult.permissionPermanentlyDenied,
        NotificationPermissionStatus.unavailable =>
          NotificationTestResult.permissionUnavailable,
        _ => NotificationTestResult.permissionDenied,
      };
    }
    final outcome = await port.showTest(title: title, body: body);
    NotificationDeliveryStatus.recordTestDelivery(
      delivered: outcome.isSuccess,
    );
    return outcome.isSuccess
        ? NotificationTestResult.sent
        : NotificationTestResult.deliveryFailed;
  }
}
