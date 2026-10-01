/// N1 — delivery foundation: confirmed scheduling, honest state, Settings test.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/notifications/local_notification_port.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/notification_delivery_state.dart';
import 'package:oracly_new/core/notifications/notification_permission.dart';
import 'package:oracly_new/core/notifications/notification_timezone.dart';
import 'package:oracly_new/core/notifications/oracly_notification_coordinator.dart';
import 'package:oracly_new/core/notifications/oracly_notification_kind.dart';
import 'package:oracly_new/core/notifications/oracly_notification_payload.dart';
import 'package:oracly_new/core/notifications/oracly_notification_test_sender.dart';
import 'package:oracly_new/core/runtime/oracly_apply_outcome.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _fln = MethodChannel('dexterous.com/flutter/local_notifications');

class _FixedPermissions implements NotificationPermissionPlatform {
  _FixedPermissions(this.status);
  NotificationPermissionStatus status;
  @override
  Future<NotificationPermissionStatus> check() async => status;
  @override
  Future<NotificationPermissionStatus> request() async => status;
}

const _daily = OraclyNotificationPayload(
  kind: OraclyNotificationKind.daily,
  title: 'ORACLY',
  body: 'Bugünün mesajı hazır.',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(NotificationDeliveryStatus.resetForTest);

  group('LocalNotificationPort on the real plugin channel', () {
    late List<MethodCall> calls;
    late List<Map<String, Object?>> pending;
    String? throwOn;

    setUp(() {
      calls = [];
      pending = [];
      throwOn = null;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      messenger.setMockMethodCallHandler(_fln, (call) async {
        calls.add(call);
        if (call.method == throwOn) throw PlatformException(code: 'boom');
        switch (call.method) {
          case 'initialize':
            return true;
          case 'zonedSchedule':
            pending.add({'id': (call.arguments as Map)['id']});
            return null;
          case 'cancel':
            final id = (call.arguments as Map)['id'];
            pending.removeWhere((p) => p['id'] == id);
            return null;
          case 'pendingNotificationRequests':
            return pending;
        }
        return null;
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(_fln, null);
      debugDefaultTargetPlatformOverride = null;
    });

    LocalNotificationPort port() => LocalNotificationPort(
      plugin: FlutterLocalNotificationsPlugin(),
      permissions: _FixedPermissions(NotificationPermissionStatus.granted),
    );

    test('a schedule counts only when the OS reports it pending', () async {
      final outcome = await port().scheduleDaily(_daily);
      expect(outcome, OraclyApplyOutcome.success);
      final methods = calls.map((c) => c.method).toList();
      expect(
        methods,
        containsAllInOrder(['cancel', 'zonedSchedule', 'pendingNotificationRequests']),
      );
      final schedule = calls.firstWhere((c) => c.method == 'zonedSchedule');
      expect((schedule.arguments as Map)['id'], 4101);
      expect((schedule.arguments as Map)['payload'], 'daily');
    });

    test('scheduled-but-not-pending is a failure with its own category', () async {
      final p = port();
      messenger.setMockMethodCallHandler(_fln, (call) async {
        if (call.method == 'pendingNotificationRequests') return <Object>[];
        if (call.method == 'initialize') return true;
        return null;
      });
      expect(await p.scheduleDaily(_daily), OraclyApplyOutcome.failure);
      expect(
        NotificationDeliveryStatus.current.lastFailure,
        NotificationFailureCategory.scheduleNotConfirmed,
      );
    });

    test('a plugin failure while scheduling is a failure', () async {
      throwOn = 'zonedSchedule';
      expect(await port().scheduleDaily(_daily), OraclyApplyOutcome.failure);
    });

    test('Settings test posts one visible high-importance notification', () async {
      final outcome = await port().showTest(title: 'ORACLY', body: 'test');
      expect(outcome, OraclyApplyOutcome.success);
      final show = calls.firstWhere((c) => c.method == 'show');
      final args = show.arguments as Map;
      expect(args['id'], LocalNotificationPort.testId);
      expect(args['id'], isNot(4101));
      expect(args['payload'], LocalNotificationPort.testPayload);
      final details = args['platformSpecifics'] as Map;
      expect(details['channelId'], 'oracly_test');
      expect(details['importance'], Importance.high.value);
    });

    test('a failing test post is reported, never claimed as sent', () async {
      throwOn = 'show';
      expect(
        await port().showTest(title: 'ORACLY', body: 'test'),
        OraclyApplyOutcome.failure,
      );
    });

    test('permission reads are recorded in the delivery state', () async {
      final p = LocalNotificationPort(
        plugin: FlutterLocalNotificationsPlugin(),
        permissions: _FixedPermissions(
          NotificationPermissionStatus.permanentlyDenied,
        ),
      );
      expect(
        await p.permissionStatus(),
        NotificationPermissionStatus.permanentlyDenied,
      );
      final state = NotificationDeliveryStatus.current;
      expect(state.permission, NotificationPermissionStatus.permanentlyDenied);
      expect(
        state.lastFailure,
        NotificationFailureCategory.permissionPermanentlyDenied,
      );
    });
  });

  group('coordinator delivery state', () {
    OraclyNotificationCoordinator coordinator(MemoryNotificationPort port) =>
        OraclyNotificationCoordinator(
          port: port,
          loadProfile: () async => PersonalDiscoveryProfile.empty,
        );

    test('enabled + granted + confirmed = locally deliverable', () async {
      final port = MemoryNotificationPort();
      final outcome = await coordinator(port).sync(
        const PersonalizationSettings(notificationsEnabled: true),
      );
      expect(outcome, OraclyApplyOutcome.success);
      final state = NotificationDeliveryStatus.current;
      expect(state.preferenceEnabled, isTrue);
      expect(state.schedule, LocalScheduleState.scheduled);
      expect(state.permission, isNull, reason: 'memory port does not record');
    });

    test('enabled but OS-blocked keeps the slot and reports failure', () async {
      final port = MemoryNotificationPort()..permissionGranted = false;
      final outcome = await coordinator(port).sync(
        const PersonalizationSettings(notificationsEnabled: true),
      );
      expect(outcome, OraclyApplyOutcome.failure);
      expect(port.scheduled?.kind, OraclyNotificationKind.daily);
      expect(
        NotificationDeliveryStatus.current.lastFailure,
        NotificationFailureCategory.permissionDenied,
      );
    });

    test('disabled preference cancels and records disabled', () async {
      final port = MemoryNotificationPort();
      await coordinator(port).sync(const PersonalizationSettings());
      expect(port.cancelCount, 1);
      expect(NotificationDeliveryStatus.current.schedule, LocalScheduleState.disabled);
      expect(NotificationDeliveryStatus.current.preferenceEnabled, isFalse);
    });

    test('schedule failure is recorded as failed', () async {
      final port = MemoryNotificationPort()..scheduleShouldFail = true;
      await coordinator(port).sync(
        const PersonalizationSettings(notificationsEnabled: true),
      );
      final state = NotificationDeliveryStatus.current;
      expect(state.schedule, LocalScheduleState.failed);
      expect(state.lastFailure, NotificationFailureCategory.scheduleFailed);
      expect(state.localDeliveryReady, isFalse);
    });

    test('cancel failure is recorded, not hidden', () async {
      final port = MemoryNotificationPort()..cancelShouldFail = true;
      await coordinator(port).sync(const PersonalizationSettings());
      expect(
        NotificationDeliveryStatus.current.lastFailure,
        NotificationFailureCategory.cancelFailed,
      );
    });
  });

  group('delivery state model', () {
    test('diagnostics carry categories only', () {
      NotificationDeliveryStatus.recordPermission(
        NotificationPermissionStatus.granted,
      );
      NotificationDeliveryStatus.recordPush(PushRegistrationState.registered);
      final diagnostics = NotificationDeliveryStatus.current.toDiagnostics();
      expect(diagnostics.keys, {
        'permission',
        'preference',
        'push',
        'schedule',
        'lastFailure',
      });
      expect(diagnostics['push'], 'registered');
    });

    test('owner boundary drops owner facts but keeps device permission', () {
      NotificationDeliveryStatus.recordPermission(
        NotificationPermissionStatus.granted,
      );
      NotificationDeliveryStatus.recordPreference(true);
      NotificationDeliveryStatus.recordSchedule(LocalScheduleState.scheduled);
      NotificationDeliveryStatus.recordPush(PushRegistrationState.registered);
      NotificationDeliveryStatus.resetForOwnerBoundary();
      final state = NotificationDeliveryStatus.current;
      expect(state.permission, NotificationPermissionStatus.granted);
      expect(state.preferenceEnabled, isNull);
      expect(state.schedule, LocalScheduleState.unknown);
      expect(state.push, PushRegistrationState.noOwner);
    });
  });

  group('timezone', () {
    setUpAll(tzdata.initializeTimeZones);
    final now = DateTime.utc(2026, 10, 1, 9);

    test('a real IANA device zone is used as-is', () {
      final location = NotificationTimezone.resolve(
        deviceZoneName: 'Europe/Berlin',
        deviceOffset: const Duration(hours: 2),
        nowUtc: now,
      );
      expect(location.name, 'Europe/Berlin');
    });

    test('an abbreviation at the Istanbul offset keeps Europe/Istanbul', () {
      final location = NotificationTimezone.resolve(
        deviceZoneName: '+03',
        deviceOffset: const Duration(hours: 3),
        nowUtc: now,
      );
      expect(location.name, 'Europe/Istanbul');
    });

    test('another offset no longer schedules on Istanbul time', () {
      final location = NotificationTimezone.resolve(
        deviceZoneName: 'IST',
        deviceOffset: const Duration(hours: 5, minutes: 30),
        nowUtc: now,
      );
      expect(location.name, isNot('Europe/Istanbul'));
      expect(
        location.timeZone(now.millisecondsSinceEpoch).offset,
        const Duration(hours: 5, minutes: 30),
      );
    });

    test('next daily slot is strictly in the future at the planned hour', () {
      final istanbul = tz.getLocation('Europe/Istanbul');
      final before = NotificationTimezone.nextDaily(
        istanbul,
        10,
        now: DateTime.utc(2026, 10, 1, 5),
      );
      expect(before.hour, 10);
      expect(before.day, 1);
      final after = NotificationTimezone.nextDaily(
        istanbul,
        10,
        now: DateTime.utc(2026, 10, 1, 8),
      );
      expect(after.day, 2);
      expect(after.hour, 10);
    });
  });

  group('Settings test sender', () {
    Future<NotificationTestResult> send(MemoryNotificationPort port) =>
        OraclyNotificationTestSender(port).send(title: 'ORACLY', body: 'ok');

    test('granted posts exactly one visible notification', () async {
      final port = MemoryNotificationPort();
      expect(await send(port), NotificationTestResult.sent);
      expect(port.shown.single.body, 'ok');
      expect(port.permissionRequests, 0);
    });

    test('never asked: prompts once, then posts when allowed', () async {
      final port = MemoryNotificationPort()
        ..permissionOverride = NotificationPermissionStatus.notDetermined
        ..statusAfterRequest = NotificationPermissionStatus.granted;
      expect(await send(port), NotificationTestResult.sent);
      expect(port.permissionRequests, 1);
      expect(port.shown, hasLength(1));
    });

    test('refused at the prompt: nothing is posted', () async {
      final port = MemoryNotificationPort()..permissionGranted = false;
      expect(await send(port), NotificationTestResult.permissionDenied);
      expect(port.shown, isEmpty);
    });

    test('permanently denied: no prompt, OS settings result', () async {
      final port = MemoryNotificationPort()
        ..permissionOverride = NotificationPermissionStatus.permanentlyDenied;
      expect(await send(port), NotificationTestResult.permissionPermanentlyDenied);
      expect(port.permissionRequests, 0);
      expect(port.shown, isEmpty);
    });

    test('unreadable permission is not treated as granted', () async {
      final port = MemoryNotificationPort()
        ..permissionOverride = NotificationPermissionStatus.unavailable;
      expect(await send(port), NotificationTestResult.permissionUnavailable);
      expect(port.shown, isEmpty);
    });

    test('a failed post is reported and recorded', () async {
      final port = MemoryNotificationPort()..showShouldFail = true;
      expect(await send(port), NotificationTestResult.deliveryFailed);
      expect(
        NotificationDeliveryStatus.current.lastFailure,
        NotificationFailureCategory.testDeliveryFailed,
      );
    });
  });
}
