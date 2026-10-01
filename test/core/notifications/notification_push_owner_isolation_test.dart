/// N1 — push registration honesty, owner isolation, tap routing safety.
library;

import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/auth/sign_out_local_cleanup.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/notification_delivery_state.dart';
import 'package:oracly_new/core/notifications/oracly_notification_providers.dart';
import 'package:oracly_new/core/notifications/notification_owner_cleanup.dart';
import 'package:oracly_new/core/notifications/notification_permission.dart';
import 'package:oracly_new/core/notifications/oracly_notification_kind.dart';
import 'package:oracly_new/core/notifications/oracly_notification_tap_background.dart';
import 'package:oracly_new/core/notifications/oracly_notification_tap_inbox.dart';
import 'package:oracly_new/core/notifications/oracly_notification_tap_router.dart';
import 'package:oracly_new/core/notifications/reading_push_bootstrap.dart';
import 'package:oracly_new/core/runtime/oracly_apply_outcome.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _TempPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _TempPathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
  @override
  Future<String?> getApplicationCachePath() async => root;
}

class _Messaging implements ReadingPushMessaging {
  final _refresh = StreamController<String>.broadcast();
  final _opened = StreamController<RemoteMessage>.broadcast();
  String? token;
  int foreground = 0;

  @override
  Future<void> setForegroundPresentation() async => foreground++;
  @override
  Future<String?> getToken() async => token;
  @override
  Stream<String> get onTokenRefresh => _refresh.stream;
  @override
  Stream<RemoteMessage> get onMessageOpenedApp => _opened.stream;
  @override
  Future<RemoteMessage?> getInitialMessage() async => null;

  void refresh(String value) => _refresh.add(value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    NotificationDeliveryStatus.resetForTest();
    AccountDeletionPendingState.markClear();
    OraclyNotificationTapInbox.instance.resetForTests();
  });

  group('push token registration', () {
    late _Messaging messaging;
    late List<String> posts;
    late int status;
    late bool throws;
    late MemoryNotificationPort port;

    setUp(() {
      messaging = _Messaging();
      posts = [];
      status = 200;
      throws = false;
      port = MemoryNotificationPort()
        ..permissionOverride = NotificationPermissionStatus.notDetermined
        ..statusAfterRequest = NotificationPermissionStatus.granted;
      ReadingPushBootstrap.messagingForTest = messaging;
      ReadingPushBootstrap.installedOwnerIdForTest = 'uid-a';
    });

    tearDown(() async {
      await ReadingPushBootstrap.cancelSubscriptionsForTest();
      ReadingPushBootstrap.messagingForTest = null;
    });

    ProviderContainer container({bool sender = true}) {
      final c = ProviderContainer(
        overrides: [
          readingOperationSenderProvider.overrideWithValue(
            sender
                ? (method, path, body) async {
                    if (throws) throw StateError('network');
                    posts.add('$path ${body?['token']}');
                    return ReadingOperationWire(statusCode: status, json: null);
                  }
                : null,
          ),
          oraclyNotificationPortProvider.overrideWithValue(port),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('COLD-START PERMISSION REQUEST COUNT = 0 across every outcome', () async {
      for (final setup in <void Function()>[
        () => messaging.token = 'tok-ok',
        () {
          messaging.token = 'tok-err';
          status = 500;
        },
        () => messaging.token = null,
      ]) {
        setup();
        await ReadingPushBootstrap.install(container());
      }
      expect(port.permissionRequests, 0);
      // The state is still read (without a prompt) so it is observable.
      expect(
        NotificationDeliveryStatus.current.permission,
        NotificationPermissionStatus.notDetermined,
      );
    });

    test('undetermined permission does not block token registration', () async {
      messaging.token = 'tok-before-opt-in';
      await ReadingPushBootstrap.install(container());
      expect(port.permissionRequests, 0);
      expect(posts, ['/v1/reading-notifications/token tok-before-opt-in']);
    });

    test('startup code contains no notification permission request', () {
      final bootstrap = File(
        'lib/core/notifications/reading_push_bootstrap.dart',
      ).readAsStringSync();
      expect(bootstrap, isNot(contains('requestPermission(')));
      expect(bootstrap, contains('setForegroundNotificationPresentationOptions('));
      for (final path in [
        'lib/main.dart',
        'lib/screens/splash/splash_boot.dart',
        'lib/core/auth/account_deletion_owner_bootstrap.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('requestPermission(')), reason: path);
        expect(source, isNot(contains('Permission.notification.request')), reason: path);
      }
    });

    test('install enables iOS foreground presentation', () async {
      messaging.token = 'tok';
      await ReadingPushBootstrap.install(container());
      expect(messaging.foreground, 1);
    });

    test('a 2xx backend answer records registered', () async {
      messaging.token = 'tok-a';
      await ReadingPushBootstrap.install(container());
      expect(posts, ['/v1/reading-notifications/token tok-a']);
      expect(NotificationDeliveryStatus.current.push, PushRegistrationState.registered);
    });

    test('a backend error is a failed registration, not success', () async {
      messaging.token = 'tok-a';
      status = 503;
      await ReadingPushBootstrap.install(container());
      final state = NotificationDeliveryStatus.current;
      expect(state.push, PushRegistrationState.failed);
      expect(state.lastFailure, NotificationFailureCategory.registrationFailed);
    });

    test('a thrown send is a failed registration', () async {
      messaging.token = 'tok-a';
      throws = true;
      await ReadingPushBootstrap.install(container());
      expect(NotificationDeliveryStatus.current.push, PushRegistrationState.failed);
    });

    test('no token: nothing is posted and the reason is recorded', () async {
      messaging.token = null;
      await ReadingPushBootstrap.install(container());
      expect(posts, isEmpty);
      final state = NotificationDeliveryStatus.current;
      expect(state.push, PushRegistrationState.tokenUnavailable);
      expect(state.lastFailure, NotificationFailureCategory.tokenUnavailable);
    });

    test('no backend sender in this build is reported as not configured', () async {
      messaging.token = 'tok-a';
      await ReadingPushBootstrap.install(container(sender: false));
      expect(
        NotificationDeliveryStatus.current.push,
        PushRegistrationState.notConfigured,
      );
    });

    test('token refresh re-registers the new token', () async {
      messaging.token = 'tok-1';
      await ReadingPushBootstrap.install(container());
      messaging.refresh('tok-2');
      await Future<void>.delayed(Duration.zero);
      expect(posts.last, '/v1/reading-notifications/token tok-2');
      expect(NotificationDeliveryStatus.current.push, PushRegistrationState.registered);
    });

    test('the delivery state never holds the token value', () async {
      messaging.token = 'secret-token-value';
      await ReadingPushBootstrap.install(container());
      final text = '${NotificationDeliveryStatus.current} '
          '${NotificationDeliveryStatus.current.toDiagnostics()}';
      expect(text, isNot(contains('secret-token-value')));
    });

    test('sign-out boundary: owner cleared, refresh no longer registers', () async {
      messaging.token = 'tok-1';
      await ReadingPushBootstrap.install(container());
      await ReadingPushBootstrap.clearOwnerBinding();
      expect(NotificationDeliveryStatus.current.push, PushRegistrationState.noOwner);
      messaging.refresh('tok-after-signout');
      await Future<void>.delayed(Duration.zero);
      expect(posts, isNot(contains(contains('tok-after-signout'))));
    });
  });

  group('owner isolation of OS-scheduled notifications', () {
    late int cancels;
    late bool cancelFails;
    late Directory root;

    setUp(() async {
      // The real wipe also deletes owned Coffee/Palm images on disk.
      root = await Directory.systemTemp.createTemp('oracly-n1-isolation-');
      PathProviderPlatform.instance = _TempPathProvider(root.path);
      cancels = 0;
      cancelFails = false;
      NotificationOwnerCleanup.cancelForTest = () async {
        cancels++;
        return cancelFails ? OraclyApplyOutcome.failure : OraclyApplyOutcome.success;
      };
    });

    tearDown(() async {
      NotificationOwnerCleanup.cancelForTest = null;
      if (root.existsSync()) await root.delete(recursive: true);
    });

    test('every account-boundary wipe cancels scheduled notifications', () async {
      NotificationDeliveryStatus.recordPreference(true);
      NotificationDeliveryStatus.recordSchedule(LocalScheduleState.scheduled);
      final result = await UserLocalDataWipe.run(
        LocalStorage.ephemeral(),
        secureStorage: InMemorySecureStorage(),
      );
      expect(cancels, 1);
      expect(result.failedOperations, isNot(contains('local_notifications')));
      expect(NotificationDeliveryStatus.current.schedule, LocalScheduleState.unknown);
      expect(NotificationDeliveryStatus.current.preferenceEnabled, isNull);
    });

    test('a failed cancel keeps the boundary incomplete (fail-closed)', () async {
      cancelFails = true;
      final result = await UserLocalDataWipe.run(
        LocalStorage.ephemeral(),
        secureStorage: InMemorySecureStorage(),
      );
      expect(result.failedOperations, contains('local_notifications'));
      expect(result.isComplete, isFalse);
    });

    test('sign-out wipe cancels the previous owner schedule', () async {
      await SignOutLocalCleanup.wipeDiskOnly(
        storage: LocalStorage.ephemeral(),
        secureStorage: InMemorySecureStorage(),
      );
      expect(cancels, 1);
    });

    test('A→B account switch cancels A\'s schedule before B is committed', () async {
      final storage = LocalStorage.ephemeral();
      final isolation = UserLocalDataIsolation(
        storage,
        secureStorage: InMemorySecureStorage(),
      );
      await isolation.onSignedIn('owner-a');
      expect(cancels, 0, reason: 'first owner: no switch, nothing to cancel');
      NotificationDeliveryStatus.recordPermission(
        NotificationPermissionStatus.granted,
      );
      NotificationDeliveryStatus.recordSchedule(LocalScheduleState.scheduled);

      final switched = await isolation.onSignedIn('owner-b');
      expect(switched.success, isTrue);
      expect(cancels, 1);
      expect(isolation.localOwnerId, 'owner-b');
      final state = NotificationDeliveryStatus.current;
      expect(state.schedule, LocalScheduleState.unknown);
      expect(state.permission, NotificationPermissionStatus.granted);
    });

    test('A→B switch is refused when A\'s schedule cannot be cancelled', () async {
      final storage = LocalStorage.ephemeral();
      final isolation = UserLocalDataIsolation(
        storage,
        secureStorage: InMemorySecureStorage(),
      );
      await isolation.onSignedIn('owner-a');
      cancelFails = true;
      final result = await isolation.onSignedIn('owner-b');
      expect(result.success, isFalse);
      expect(result.wipeResult?.failedOperations, contains('local_notifications'));
      expect(isolation.localOwnerId, 'owner-a');
    });
  });

  group('local notification taps', () {
    NotificationResponse response(String? payload) => NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: payload,
    );

    test('background tap is queued, not dropped', () {
      oraclyNotificationTapBackground(response('daily'));
      expect(
        OraclyNotificationTapInbox.instance.pendingKind,
        OraclyNotificationKind.daily,
      );
    });

    test('cold-start tap waits until navigation is ready', () {
      OraclyNotificationTapRouter.offerPayload('companion');
      OraclyNotificationTapRouter.openPending();
      expect(
        OraclyNotificationTapInbox.instance.pendingKind,
        OraclyNotificationKind.companion,
        reason: 'no shell/navigator yet: must stay queued',
      );
    });

    test('the Settings test notification never routes anywhere', () {
      oraclyNotificationTapBackground(response('oracly_test'));
      expect(OraclyNotificationTapInbox.instance.pendingKind, isNull);
    });

    test('invalid payloads are rejected', () {
      for (final bad in [null, '', '   ', 'Daily', 'reading_completed', '{"k":"daily"}']) {
        oraclyNotificationTapBackground(response(bad));
      }
      expect(OraclyNotificationTapInbox.instance.pendingKind, isNull);
    });
  });

  group('reading completion payload validation', () {
    const id = '0123456789abcdef0123456789abcdef';

    test('Coffee/Palm/SoulMate completions map to their screens', () {
      for (final type in ['coffee', 'palm', 'soulmate']) {
        final destination = readingPushDestination({
          'type': 'reading_completed',
          'readingType': type,
          'operationId': id,
        });
        expect(destination?.operationId, id, reason: type);
      }
    });

    test('unknown type, wrong kind or malformed id is rejected', () {
      expect(
        readingPushDestination({
          'type': 'reading_completed',
          'readingType': 'tarot',
          'operationId': id,
        }),
        isNull,
      );
      expect(
        readingPushDestination({
          'type': 'marketing',
          'readingType': 'coffee',
          'operationId': id,
        }),
        isNull,
      );
      for (final badId in ['', 'ABC', '${id}0', '../etc', id.toUpperCase()]) {
        expect(
          readingPushDestination({
            'type': 'reading_completed',
            'readingType': 'coffee',
            'operationId': badId,
          }),
          isNull,
          reason: badId,
        );
      }
    });
  });
}
