/// N1 — authoritative notification permission on iOS and Android.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/notifications/notification_permission.dart';

const _fln = MethodChannel('dexterous.com/flutter/local_notifications');
const _ph = MethodChannel('flutter.baseflow.com/permissions/methods');

/// permission_handler wire values: denied=0, granted=1, permanentlyDenied=4.
const _phDenied = 0;
const _phGranted = 1;
const _phPermanentlyDenied = 4;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<String> flnCalls;
  late List<String> phCalls;
  Map<String, Object?> iosOptions = {};
  bool? iosRequestResult;
  bool? androidEnabled;
  int phStatus = _phDenied;
  bool flnThrows = false;

  setUp(() {
    flnCalls = [];
    phCalls = [];
    iosOptions = {'isEnabled': false};
    iosRequestResult = false;
    androidEnabled = false;
    phStatus = _phDenied;
    flnThrows = false;
    messenger.setMockMethodCallHandler(_fln, (call) async {
      flnCalls.add(call.method);
      if (flnThrows) throw PlatformException(code: 'boom');
      switch (call.method) {
        case 'checkPermissions':
          return iosOptions;
        case 'requestPermissions':
          if (iosRequestResult == true) {
            iosOptions = {'isEnabled': true, 'isAlertEnabled': true};
          }
          return iosRequestResult;
        case 'areNotificationsEnabled':
          return androidEnabled;
        case 'requestNotificationsPermission':
          return androidEnabled;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(_ph, (call) async {
      phCalls.add(call.method);
      return phStatus;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_fln, null);
    messenger.setMockMethodCallHandler(_ph, null);
    debugDefaultTargetPlatformOverride = null;
  });

  DeviceNotificationPermissionPlatform ios() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    return DeviceNotificationPermissionPlatform(
      FlutterLocalNotificationsPlugin(),
    );
  }

  DeviceNotificationPermissionPlatform android() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    return DeviceNotificationPermissionPlatform(
      FlutterLocalNotificationsPlugin(),
    );
  }

  group('iOS', () {
    test('granted alerts read as granted — never via permission_handler', () async {
      iosOptions = {'isEnabled': true, 'isAlertEnabled': true};
      expect(await ios().check(), NotificationPermissionStatus.granted);
      expect(phCalls, isEmpty);
    });

    test('provisional-only authorization is still deliverable', () async {
      iosOptions = {'isEnabled': true, 'isProvisionalEnabled': true};
      final status = await ios().check();
      expect(status, NotificationPermissionStatus.provisional);
      expect(status.canDeliver, isTrue);
    });

    test('not enabled reads as denied, not as a fake permanent block', () async {
      expect(await ios().check(), NotificationPermissionStatus.denied);
    });

    test('accepting the system prompt yields granted', () async {
      iosRequestResult = true;
      expect(await ios().request(), NotificationPermissionStatus.granted);
      expect(flnCalls, containsAllInOrder(['requestPermissions', 'checkPermissions']));
      expect(phCalls, isEmpty);
    });

    test('a refusal is permanent on iOS (Settings is the only way back)', () async {
      iosRequestResult = false;
      final status = await ios().request();
      expect(status, NotificationPermissionStatus.permanentlyDenied);
      expect(status.needsOsSettings, isTrue);
      expect(phCalls, isEmpty);
    });

    test('a platform failure is unavailable, never granted', () async {
      flnThrows = true;
      final p = ios();
      expect(await p.check(), NotificationPermissionStatus.unavailable);
      expect(await p.request(), NotificationPermissionStatus.unavailable);
    });
  });

  group('Android', () {
    test('app notifications enabled reads as granted', () async {
      androidEnabled = true;
      expect(await android().check(), NotificationPermissionStatus.granted);
    });

    test('disabled with a re-askable runtime permission is denied', () async {
      androidEnabled = false;
      phStatus = _phDenied;
      expect(await android().check(), NotificationPermissionStatus.denied);
    });

    test('disabled and permanently refused needs OS settings', () async {
      androidEnabled = false;
      phStatus = _phPermanentlyDenied;
      expect(
        await android().check(),
        NotificationPermissionStatus.permanentlyDenied,
      );
    });

    test('runtime permission granted but app notifications switched off '
        'can only be fixed in OS settings', () async {
      androidEnabled = false;
      phStatus = _phGranted;
      expect(
        await android().check(),
        NotificationPermissionStatus.permanentlyDenied,
      );
    });

    test('request then enabled yields granted', () async {
      androidEnabled = true;
      expect(await android().request(), NotificationPermissionStatus.granted);
      expect(flnCalls, contains('requestNotificationsPermission'));
    });
  });
}
