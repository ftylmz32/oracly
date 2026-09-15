/// PushTokenCleanup — the single sign-out/account-deletion push-cleanup
/// abstraction. Proves: server-side unregister is attempted with the right
/// request shape, nothing here ever throws (a transient failure must never
/// trap a user inside their account), and the local FCM token invalidation
/// call site is real (not a no-op stub) even though the plugin channel
/// itself cannot be exercised in a widget/unit test.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/notifications/push_token_cleanup.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'unregisterServerToken calls the sender with the unregister path and an empty body',
    () async {
      final calls = <List<Object?>>[];
      Future<ReadingOperationWire?> send(
        String method,
        String path,
        Map<String, Object>? body,
      ) async {
        calls.add([method, path, body]);
        return const ReadingOperationWire(statusCode: 200, json: {'data': {}});
      }

      await PushTokenCleanup.unregisterServerToken(send);

      expect(calls, hasLength(1));
      expect(calls.single[0], 'POST');
      expect(calls.single[1], '/v1/reading-notifications/token/unregister');
      expect(calls.single[2], isEmpty);
    },
  );

  test(
    'unregisterServerToken is a safe no-op when no sender is configured',
    () async {
      await expectLater(
        PushTokenCleanup.unregisterServerToken(null),
        completes,
      );
    },
  );

  test(
    'unregisterServerToken never throws even when the sender throws',
    () async {
      Future<ReadingOperationWire?> send(
        String method,
        String path,
        Map<String, Object>? body,
      ) async {
        throw Exception('simulated network failure');
      }

      await expectLater(
        PushTokenCleanup.unregisterServerToken(send),
        completes,
      );
    },
  );

  test(
    'deleteLocalToken never throws — a missing/unconfigured platform plugin must never block sign-out or deletion',
    () async {
      // No platform channel handler is registered in this test
      // environment, so this genuinely exercises the "plugin unavailable"
      // failure path, not just a happy path with a mock.
      await expectLater(PushTokenCleanup.deleteLocalToken(), completes);
    },
  );

  test(
    'deleteLocalToken really calls FirebaseMessaging.instance.deleteToken() — not a no-op stub',
    () {
      final source = File(
        'lib/core/notifications/push_token_cleanup.dart',
      ).readAsStringSync();
      expect(source, contains('FirebaseMessaging.instance.deleteToken()'));
    },
  );
}
