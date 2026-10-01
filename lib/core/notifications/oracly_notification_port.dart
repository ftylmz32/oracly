/// Local notification sink. Tests use a memory implementation.
library;

import '../runtime/oracly_apply_outcome.dart';
import 'notification_permission.dart';
import 'oracly_notification_payload.dart';

abstract class OraclyNotificationPort {
  Future<void> initialize();

  /// Current OS permission, without prompting. Never throws.
  Future<NotificationPermissionStatus> permissionStatus();

  /// Prompts when the OS still allows it, then reports the real state.
  /// Never throws.
  Future<NotificationPermissionStatus> requestPermission();

  /// Never throws — a real plugin/platform failure, or a schedule the OS does
  /// not confirm as pending, is reported as [OraclyApplyOutcome.failure].
  Future<OraclyApplyOutcome> scheduleDaily(OraclyNotificationPayload payload);

  /// Never throws — see [scheduleDaily].
  Future<OraclyApplyOutcome> cancelAll();

  /// Posts one visible notification right now (user-triggered Settings test
  /// only). Never throws.
  Future<OraclyApplyOutcome> showTest({
    required String title,
    required String body,
  });

  /// Reads cold-start notification response, if any.
  Future<void> captureColdStartLaunch();
}
