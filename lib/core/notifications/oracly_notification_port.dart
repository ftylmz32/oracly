/// Local notification sink. Tests use a memory implementation.
library;

import '../runtime/oracly_apply_outcome.dart';
import 'oracly_notification_payload.dart';

abstract class OraclyNotificationPort {
  Future<void> initialize();

  Future<bool> requestPermission();

  /// Never throws — a real plugin/platform failure is reported as
  /// [OraclyApplyOutcome.failure], not silently swallowed.
  Future<OraclyApplyOutcome> scheduleDaily(OraclyNotificationPayload payload);

  /// Never throws — see [scheduleDaily].
  Future<OraclyApplyOutcome> cancelAll();

  /// Reads cold-start notification response, if any.
  Future<void> captureColdStartLaunch();
}
