/// Explicit push-token cleanup for sign-out / account deletion.
///
/// Sign-out and account-deletion flows call this instead of talking to
/// `FirebaseMessaging` directly, so the cleanup contract lives in one
/// place rather than scattered through UI widgets.
library;

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/reading_operation/services/reading_operation_gateway.dart';

abstract final class PushTokenCleanup {
  PushTokenCleanup._();

  /// Best-effort server-side unregister for the CURRENT authenticated
  /// identity's push token. Must be called while that identity's auth is
  /// still valid — ownership is derived server-side from the request's
  /// verified identity; nothing here ever sends a token value, so there
  /// is nothing raw to log. Never throws: a transient failure here must
  /// never trap a user inside their account.
  static Future<void> unregisterServerToken(ReadingOperationSender? send) async {
    if (send == null) return;
    try {
      await send('POST', '/v1/reading-notifications/token/unregister', const {});
    } catch (_) {
      // Best-effort — must never block sign-out or account deletion.
    }
  }

  /// Deletes the local FCM registration token so this device instance
  /// stops being a valid delivery target, independent of server-side
  /// cleanup. Never throws for the same reason as above.
  static Future<void> deleteLocalToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Platform/plugin failure — must never block sign-out or deletion.
    }
  }
}
