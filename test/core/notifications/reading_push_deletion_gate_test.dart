/// Reading push must not register or navigate while gate ≠ clear.
library;

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
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
  Future<RemoteMessage?> getInitialMessage() async => null;

  void emitRefresh(String value) => _refresh.add(value);
}
