/// Device local notifications — one inexact daily slot, never stacked.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'oracly_notification_payload.dart';
import 'oracly_notification_planner.dart';
import 'oracly_notification_port.dart';
import 'oracly_notification_tap_background.dart';
import 'oracly_notification_tap_router.dart';

class LocalNotificationPort implements OraclyNotificationPort {
  LocalNotificationPort({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _id = 4101;
  static const _channel = 'oracly_return';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  @override
  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (_) {}
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      init,
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
  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidOk =
          await android?.requestNotificationsPermission() ?? true;
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosOk = await ios?.requestPermissions(alert: true, sound: true) ??
          true;
      final os = await Permission.notification.request();
      return androidOk && iosOk && os.isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> scheduleDaily(OraclyNotificationPayload payload) async {
    await initialize();
    await _plugin.cancel(_id);
    await _plugin.zonedSchedule(
      _id,
      payload.title,
      payload.body,
      _nextDaily(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channel,
          'ORACLY',
          channelDescription: 'Gentle daily invitations',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload.kind.name,
    );
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancel(_id);
      await _plugin.cancelAll();
    } catch (_) {}
  }

  tz.TZDateTime _nextDaily() {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      OraclyNotificationPlanner.dailyHour,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }
}
