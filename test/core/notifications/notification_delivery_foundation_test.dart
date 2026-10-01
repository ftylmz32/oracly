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

    test('the device IANA zone is what the native scheduler receives', () async {
      final p = LocalNotificationPort(
        plugin: FlutterLocalNotificationsPlugin(),
        permissions: _FixedPermissions(NotificationPermissionStatus.granted),
        deviceTimezone: () async => 'America/New_York',
      );
      expect(await p.scheduleDaily(_daily), OraclyApplyOutcome.success);
      final args =
          calls.firstWhere((c) => c.method == 'zonedSchedule').arguments as Map;
      expect(args['timeZoneName'], 'America/New_York');
      expect(p.timezoneForTest?.isExactDeviceZone, isTrue);
      expect(
        NotificationDeliveryStatus.current.timezone,
        NotificationTimezoneSource.device,
      );
    });

    test('no device zone: schedules on the product default, recorded as a '
        'fallback rather than a device zone', () async {
      final p = LocalNotificationPort(
        plugin: FlutterLocalNotificationsPlugin(),
        permissions: _FixedPermissions(NotificationPermissionStatus.granted),
        deviceTimezone: () async => null,
      );
      await p.scheduleDaily(_daily);
      final args =
          calls.firstWhere((c) => c.method == 'zonedSchedule').arguments as Map;
      expect(args['timeZoneName'], NotificationTimezone.defaultZone);
      expect(p.timezoneForTest?.isExactDeviceZone, isFalse);
      expect(
        NotificationDeliveryStatus.current.toDiagnostics()['timezone'],
        'fallback',
      );
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
      expect(state.permission, NotificationPermissionStatus.granted);
      expect(state.localDeliveryReady, isTrue);
      expect(state.lastFailure, isNull);
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
        'timezone',
        'lastFailure',
        'activeFailures',
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

  group('device timezone', () {
    setUpAll(tzdata.initializeTimeZones);

    test('the device IANA zone is used and marked exact', () {
      final resolved = NotificationTimezone.resolve('America/New_York');
      expect(resolved.location.name, 'America/New_York');
      expect(resolved.isExactDeviceZone, isTrue);
    });

    test('missing or unknown device zone falls back, never claimed exact', () {
      for (final input in [null, '', '  ', 'GMT+03:00', 'TRT', 'Not/AZone']) {
        final resolved = NotificationTimezone.resolve(input);
        expect(resolved.location.name, NotificationTimezone.defaultZone);
        expect(resolved.isExactDeviceZone, isFalse, reason: '$input');
        expect(resolved.source, NotificationTimezoneSource.fallback);
      }
    });

    test('ambiguous offset: zones equal today diverge after DST — so no '
        'offset guess is ever used', () {
      final berlin = tz.getLocation('Europe/Berlin');
      final joburg = tz.getLocation('Africa/Johannesburg');
      final summer = DateTime.utc(2026, 10, 1).millisecondsSinceEpoch;
      final winter = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch;
      // Same +02:00 today…
      expect(
        berlin.timeZone(summer).offset,
        joburg.timeZone(summer).offset,
      );
      // …different after 25 Oct 2026: a guess from today's offset would put
      // a Berlin user's daily invitation an hour off all winter.
      expect(berlin.timeZone(winter).offset, const Duration(hours: 1));
      expect(joburg.timeZone(winter).offset, const Duration(hours: 2));
      expect(
        NotificationTimezone.resolve('Europe/Berlin').location.name,
        'Europe/Berlin',
      );
    });

    test('DST end (25 Oct 2026): next slot stays at 10:00 local wall time', () {
      final berlin = tz.getLocation('Europe/Berlin');
      final next = NotificationTimezone.nextDaily(
        berlin,
        10,
        now: DateTime.utc(2026, 10, 24, 12),
      );
      expect(next.day, 25);
      expect(next.hour, 10);
      expect(next.timeZoneOffset, const Duration(hours: 1));
      expect(next.toUtc().hour, 9);
    });

    test('DST start (29 Mar 2026): next slot stays at 10:00 local wall time', () {
      final berlin = tz.getLocation('Europe/Berlin');
      final next = NotificationTimezone.nextDaily(
        berlin,
        10,
        now: DateTime.utc(2026, 3, 28, 12),
      );
      expect(next.day, 29);
      expect(next.hour, 10);
      expect(next.timeZoneOffset, const Duration(hours: 2));
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

  group('stale failure transitions (failure domains)', () {
    NotificationFailureCategory? last() =>
        NotificationDeliveryStatus.current.lastFailure;

    test('1. registrationFailed → registered clears the push failure', () {
      NotificationDeliveryStatus.recordPush(PushRegistrationState.failed);
      expect(last(), NotificationFailureCategory.registrationFailed);
      NotificationDeliveryStatus.recordPush(PushRegistrationState.registered);
      expect(last(), isNull);
    });

    test('2. tokenUnavailable → registered clears the token failure', () {
      NotificationDeliveryStatus.recordPush(
        PushRegistrationState.tokenUnavailable,
      );
      expect(last(), NotificationFailureCategory.tokenUnavailable);
      NotificationDeliveryStatus.recordPush(PushRegistrationState.registered);
      expect(last(), isNull);
    });

    test('3. scheduleFailed → scheduled clears the schedule failure', () {
      NotificationDeliveryStatus.recordSchedule(LocalScheduleState.failed);
      expect(last(), NotificationFailureCategory.scheduleFailed);
      NotificationDeliveryStatus.recordSchedule(LocalScheduleState.scheduled);
      expect(last(), isNull);
    });

    test('4. scheduleNotConfirmed → scheduled clears it (and a generic '
        'failed report does not overwrite the precise category)', () {
      NotificationDeliveryStatus.recordFailure(
        NotificationFailureCategory.scheduleNotConfirmed,
      );
      NotificationDeliveryStatus.recordSchedule(LocalScheduleState.failed);
      expect(last(), NotificationFailureCategory.scheduleNotConfirmed);
      NotificationDeliveryStatus.recordSchedule(LocalScheduleState.scheduled);
      expect(last(), isNull);
    });

    test('5. permissionDenied → granted clears the permission failure', () {
      NotificationDeliveryStatus.recordPermission(
        NotificationPermissionStatus.denied,
      );
      expect(last(), NotificationFailureCategory.permissionDenied);
      NotificationDeliveryStatus.recordPermission(
        NotificationPermissionStatus.granted,
      );
      expect(last(), isNull);
    });

    test('6. permanentlyDenied → granted (OS Settings changed) clears it', () {
      NotificationDeliveryStatus.recordPermission(
        NotificationPermissionStatus.permanentlyDenied,
      );
      expect(last(), NotificationFailureCategory.permissionPermanentlyDenied);
      NotificationDeliveryStatus.recordPermission(
        NotificationPermissionStatus.granted,
      );
      expect(last(), isNull);
      expect(
        NotificationDeliveryStatus.current.permission,
        NotificationPermissionStatus.granted,
      );
    });

    test('7. testDeliveryFailed → successful test clears the test failure', () {
      NotificationDeliveryStatus.recordTestDelivery(delivered: false);
      expect(last(), NotificationFailureCategory.testDeliveryFailed);
      NotificationDeliveryStatus.recordTestDelivery(delivered: true);
      expect(last(), isNull);
    });

    test('a recovered domain never erases an unrelated current failure', () {
      NotificationDeliveryStatus.recordPermission(
        NotificationPermissionStatus.denied,
      );
      NotificationDeliveryStatus.recordPush(PushRegistrationState.failed);
      NotificationDeliveryStatus.recordSchedule(LocalScheduleState.failed);

      NotificationDeliveryStatus.recordPush(PushRegistrationState.registered);
      NotificationDeliveryStatus.recordTestDelivery(delivered: true);
      final state = NotificationDeliveryStatus.current;
      expect(state.activeFailures, [
        NotificationFailureCategory.permissionDenied,
        NotificationFailureCategory.scheduleFailed,
      ]);
      expect(state.lastFailure, NotificationFailureCategory.scheduleFailed);

      NotificationDeliveryStatus.recordSchedule(LocalScheduleState.scheduled);
      expect(
        NotificationDeliveryStatus.current.lastFailure,
        NotificationFailureCategory.permissionDenied,
        reason: 'permission is still denied — must stay visible',
      );
    });

    test('one failure per domain: a newer failure replaces the older one', () {
      NotificationDeliveryStatus.recordPush(
        PushRegistrationState.tokenUnavailable,
      );
      NotificationDeliveryStatus.recordPush(PushRegistrationState.failed);
      expect(NotificationDeliveryStatus.current.activeFailures, [
        NotificationFailureCategory.registrationFailed,
      ]);
    });

    test('owner boundary keeps the device permission failure only', () {
      NotificationDeliveryStatus.recordPermission(
        NotificationPermissionStatus.permanentlyDenied,
      );
      NotificationDeliveryStatus.recordPush(PushRegistrationState.failed);
      NotificationDeliveryStatus.resetForOwnerBoundary();
      expect(NotificationDeliveryStatus.current.activeFailures, [
        NotificationFailureCategory.permissionPermanentlyDenied,
      ]);
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
