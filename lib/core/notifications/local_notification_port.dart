/// Device local notifications — one inexact daily slot, never stacked.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../runtime/oracly_apply_outcome.dart';
import 'notification_delivery_state.dart';
import 'notification_permission.dart';
import 'notification_timezone.dart';
import 'oracly_notification_payload.dart';
import 'oracly_notification_planner.dart';
import 'oracly_notification_port.dart';
import 'oracly_notification_tap_background.dart';
import 'oracly_notification_tap_router.dart';

class LocalNotificationPort implements OraclyNotificationPort {
  LocalNotificationPort({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationPermissionPlatform? permissions,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _permissionsOverride = permissions;

  /// One plugin binding per process: the provider and the account-boundary
  /// cleanup must cancel/schedule through the same instance.
  static final LocalNotificationPort shared = LocalNotificationPort();

  static const _id = 4101;
  static const _channel = 'oracly_return';

  /// User-triggered Settings test only. Separate id: never replaces the
  /// daily slot. Separate high-importance channel so it is visibly shown.
  static const testId = 4102;
  static const _testChannel = 'oracly_test';

  /// Not a [OraclyNotificationKind]: the tap inbox ignores it, so tapping the
  /// test opens the app without navigating anywhere.
  static const testPayload = 'oracly_test';

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationPermissionPlatform? _permissionsOverride;
  late final NotificationPermissionPlatform _permissions =
      _permissionsOverride ?? DeviceNotificationPermissionPlatform(_plugin);
  bool _ready = false;
  tz.Location? _location;

  static const _darwinVisible = DarwinNotificationDetails(
    presentAlert: true,
    presentBanner: true,
    presentList: true,
    presentBadge: false,
    presentSound: true,
  );

  @override
  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    final now = DateTime.now();
    try {
      _location = NotificationTimezone.resolve(
        deviceZoneName: now.timeZoneName,
        deviceOffset: now.timeZoneOffset,
        nowUtc: now.toUtc(),
      );
    } catch (_) {
      _location = tz.getLocation(NotificationTimezone.defaultZone);
    }
    tz.setLocalLocation(_location!);
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
        defaultPresentSound: true,
      ),
    );
    await _plugin.initialize(
      settings: init,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: oraclyNotificationTapBackground,
    );
    _ready = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    OraclyNotificationTapRouter.offerPayload(response.payload);
    OraclyNotificationTapRouter.openPending();
  }

  @override
  Future<void> captureColdStartLaunch() async {
    await initialize();
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        OraclyNotificationTapRouter.offerPayload(
          details!.notificationResponse?.payload,
        );
      }
    } catch (_) {}
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    try {
      await initialize();
    } catch (_) {}
    final status = await _permissions.check();
    NotificationDeliveryStatus.recordPermission(status);
    return status;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    try {
      await initialize();
    } catch (_) {}
    final status = await _permissions.request();
    NotificationDeliveryStatus.recordPermission(status);
    return status;
  }

  @override
  Future<OraclyApplyOutcome> scheduleDaily(
    OraclyNotificationPayload payload,
  ) async {
    try {
      await initialize();
      await _plugin.cancel(id: _id);
      await _plugin.zonedSchedule(
        id: _id,
        title: payload.title,
        body: payload.body,
        scheduledDate: NotificationTimezone.nextDaily(
          _location ?? tz.local,
          OraclyNotificationPlanner.dailyHour,
        ),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channel,
            'ORACLY',
            channelDescription: 'Gentle daily invitations',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: _darwinVisible,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload.kind.name,
      );
    } catch (e) {
      debugPrint('[ORACLY] scheduleDaily failed: $e');
      return OraclyApplyOutcome.failure;
    }
    // "No exception" is not proof: the OS must report the slot as pending.
    try {
      final pending = await _plugin.pendingNotificationRequests();
      if (pending.any((request) => request.id == _id)) {
        return OraclyApplyOutcome.success;
      }
    } catch (e) {
      debugPrint('[ORACLY] scheduleDaily confirmation failed: $e');
    }
    NotificationDeliveryStatus.recordFailure(
      NotificationFailureCategory.scheduleNotConfirmed,
    );
    return OraclyApplyOutcome.failure;
  }

  @override
  Future<OraclyApplyOutcome> cancelAll() async {
    try {
      await initialize();
      await _plugin.cancel(id: _id);
      await _plugin.cancelAll();
      return OraclyApplyOutcome.success;
    } catch (e) {
      debugPrint('[ORACLY] notification cancelAll failed: $e');
      return OraclyApplyOutcome.failure;
    }
  }

  @override
  Future<OraclyApplyOutcome> showTest({
    required String title,
    required String body,
  }) async {
    try {
      await initialize();
      await _plugin.show(
        id: testId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _testChannel,
            'ORACLY test',
            channelDescription: 'Notification check started from Settings',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: _darwinVisible,
        ),
        payload: testPayload,
      );
      return OraclyApplyOutcome.success;
    } catch (e) {
      debugPrint('[ORACLY] test notification failed: $e');
      return OraclyApplyOutcome.failure;
    }
  }
}
