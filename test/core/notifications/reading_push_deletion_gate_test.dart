/// Reading push must not register or navigate while gate ≠ clear.
library;

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:oracly_new/shared/navigation/oracly_shell_bridge.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation_scope.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/core/navigation/oracly_navigator_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/notifications/reading_push_bootstrap.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeMessaging messaging;
  late List<String> posts;
  late ProviderContainer container;

  setUp(() {
    AccountDeletionPendingState.markClear();
    messaging = _FakeMessaging();
    ReadingPushBootstrap.messagingForTest = messaging;
    posts = <String>[];
    container = ProviderContainer(
      overrides: [
        readingOperationSenderProvider.overrideWithValue(
          (method, path, body) async {
            posts.add('$method $path ${body?['token']}');
            return null;
          },
        ),
      ],
    );
  });

  tearDown(() async {
    await ReadingPushBootstrap.cancelSubscriptionsForTest();
    ReadingPushBootstrap.messagingForTest = null;
    container.dispose();
    AccountDeletionPendingState.markClear();
  });

  test('blocked install: no permission, token, or registration', () async {
    AccountDeletionPendingState.markBlocked();
    await ReadingPushBootstrap.install(container);
    expect(messaging.permissionRequests, 0);
    expect(messaging.tokenFetches, 0);
    expect(posts, isEmpty);
  });

  test('storageUnavailable install: no Firebase work', () async {
    AccountDeletionPendingState.markStorageUnavailable();
    await ReadingPushBootstrap.install(container);
    expect(messaging.permissionRequests, 0);
    expect(messaging.tokenFetches, 0);
    expect(posts, isEmpty);
  });

  test('clear install registers token', () async {
    messaging.token = 'tok-new';
    await ReadingPushBootstrap.install(container);
    expect(messaging.permissionRequests, 1);
    expect(messaging.tokenFetches, 1);
    expect(posts, ['POST /v1/reading-notifications/token tok-new']);
  });

  test('blocked token-refresh callback does not register', () async {
    messaging.token = 'tok-1';
    await ReadingPushBootstrap.install(container);
    expect(posts.length, 1);

    AccountDeletionPendingState.markBlocked();
    messaging.emitRefresh('tok-blocked');
    await Future<void>.delayed(Duration.zero);
    expect(posts, ['POST /v1/reading-notifications/token tok-1']);
  });

  testWidgets(
    'cold-start reading completion waits for shell then opens exact operation once',
    (tester) async {
      final id = 'e' * 32;
      messaging.initial = RemoteMessage(
        data: {
          'type': 'reading_completed',
          'readingType': 'coffee',
          'operationId': id,
        },
      );

      // Installation happens during deferred owner bootstrap while Splash may
      // still own the root navigator. The target must remain queued.
      await ReadingPushBootstrap.install(container);
      expect(
        ReadingPushBootstrap.pendingDestinationForTest?.operationId,
        id,
      );

      RouteSettings? opened;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: oraclyNavigatorKey,
          onGenerateRoute: (settings) {
            opened = settings;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('reading-target')),
            );
          },
          home: const Scaffold(body: Text('home')),
        ),
      );

      void switcher(OraclyTab _) {}
      OraclyShellBridge.bind(switcher);
      addTearDown(() => OraclyShellBridge.unbind(switcher));

      ReadingPushBootstrap.openPending();
      await tester.pump();
      await tester.pump();

      expect(opened?.name, OraclyRoutes.coffee);
      expect(
        (opened?.arguments as Map?)?['operationId'],
        id,
      );
      expect(ReadingPushBootstrap.pendingDestinationForTest, isNull);

      // Queue was consumed — a second drain cannot double-open it.
      opened = null;
      ReadingPushBootstrap.openPending();
      await tester.pump();
      expect(opened, isNull);
    },
  );

  testWidgets(
    'installed reading listener queues completion while gate is blocked then opens after clear',
    (tester) async {
      final id = 'f' * 32;
      await ReadingPushBootstrap.install(container);

      AccountDeletionPendingState.markBlocked();
      messaging.emitOpened(
        RemoteMessage(
          data: {
            'type': 'reading_completed',
            'readingType': 'palm',
            'operationId': id,
          },
        ),
      );
      await tester.pump();

      expect(
        ReadingPushBootstrap.pendingDestinationForTest?.operationId,
        id,
      );

      RouteSettings? opened;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: oraclyNavigatorKey,
          onGenerateRoute: (settings) {
            opened = settings;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('reading-target')),
            );
          },
          home: const Scaffold(body: Text('home')),
        ),
      );

      void switcher(OraclyTab _) {}
      OraclyShellBridge.bind(switcher);
      addTearDown(() => OraclyShellBridge.unbind(switcher));

      ReadingPushBootstrap.openPending();
      await tester.pump();
      expect(opened, isNull);
      expect(
        ReadingPushBootstrap.pendingDestinationForTest?.operationId,
        id,
      );

      AccountDeletionPendingState.markClear();
      ReadingPushBootstrap.openPending();
      await tester.pump();
      await tester.pump();

      expect(opened?.name, OraclyRoutes.palm);
      expect((opened?.arguments as Map?)?['operationId'], id);
      expect(ReadingPushBootstrap.pendingDestinationForTest, isNull);
    },
  );

  test('blocked reading notification does not navigate', () async {
    AccountDeletionPendingState.markBlocked();
    final id = 'c' * 32;
    // openReading is private — prove mapping still works, and install path
    // never wires listeners while blocked (permission/token = 0 above).
    expect(
      readingPushDestination({
        'type': 'reading_completed',
        'readingType': 'coffee',
        'operationId': id,
      })?.route,
      isNotNull,
    );
    await ReadingPushBootstrap.install(container);
    expect(messaging.openedListeners, 0);
  });
}

class _FakeMessaging implements ReadingPushMessaging {
  final _refresh = StreamController<String>.broadcast();
  final _opened = StreamController<RemoteMessage>.broadcast();
  String? token;
  RemoteMessage? initial;
  int permissionRequests = 0;
  int tokenFetches = 0;
  int openedListeners = 0;

  @override
  Future<void> requestPermission() async {
    permissionRequests++;
  }

  @override
  Future<String?> getToken() async {
    tokenFetches++;
    return token;
  }

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp {
    openedListeners++;
    return _opened.stream;
  }

  @override
  Future<RemoteMessage?> getInitialMessage() async => initial;

  void emitRefresh(String value) => _refresh.add(value);

  void emitOpened(RemoteMessage message) => _opened.add(message);
}
