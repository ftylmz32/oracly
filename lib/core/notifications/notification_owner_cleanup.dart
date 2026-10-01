/// Account-boundary cleanup for device-scheduled notifications.
///
/// A daily invitation scheduled for owner A is held by the OS, not by app
/// storage — without this, it keeps firing for owner B after sign-out,
/// account switch or deletion (and its discovery variant can name A's theme).
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../runtime/oracly_apply_outcome.dart';
import 'local_notification_port.dart';
import 'notification_delivery_state.dart';

abstract final class NotificationOwnerCleanup {
  NotificationOwnerCleanup._();

  static Future<OraclyApplyOutcome> Function()? _cancelOverride;

  /// Cancels every scheduled/delivered ORACLY local notification and drops
  /// owner-bound delivery facts. Throws when the OS cancellation fails so
  /// the caller's wipe reports the boundary as incomplete (fail-closed).
  static Future<void> run() async {
    NotificationDeliveryStatus.resetForOwnerBoundary();
    final override = _cancelOverride;
    if (override == null && !_onDevice) return;
    final outcome =
        await (override?.call() ?? LocalNotificationPort.shared.cancelAll());
    if (outcome.isFailure) {
      throw StateError('scheduled notifications were not cancelled');
    }
  }

  /// Host test runners (and widget tests, which only *pretend* to be
  /// Android) have no notification plugin.
  static bool get _onDevice =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @visibleForTesting
  static set cancelForTest(Future<OraclyApplyOutcome> Function()? cancel) =>
      _cancelOverride = cancel;
}
