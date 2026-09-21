/// Completion-only Firebase Messaging bootstrap for durable Coffee/Palm jobs.
library;

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/reading_operation/providers/reading_live_provider.dart';
import '../auth/account_deletion_pending_state.dart';
import '../navigation/oracly_navigator_key.dart';
import '../navigation/oracly_routes.dart';
import '../../shared/navigation/oracly_shell_bridge.dart';

/// Injectable messaging surface for unit tests (no Firebase platform).
@visibleForTesting
abstract class ReadingPushMessaging {
  Future<void> requestPermission();
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Stream<RemoteMessage> get onMessageOpenedApp;
  Future<RemoteMessage?> getInitialMessage();
}

abstract final class ReadingPushBootstrap {
  ReadingPushBootstrap._();

  static StreamSubscription<String>? _refresh;
  static StreamSubscription<RemoteMessage>? _opened;
  static ReadingPushDestination? _pendingDestination;

  @visibleForTesting
  static ReadingPushMessaging? messagingForTest;

  static Future<void> install(ProviderContainer container) async {
    if (!AccountDeletionPendingState.allowsOwnerBoundExperience) return;
    try {
      final messaging = messagingForTest;
      if (messaging != null) {
        await _installWith(messaging, container);
        return;
      }
      final firebase = FirebaseMessaging.instance;
      await firebase.requestPermission(alert: true, badge: true, sound: true);
      final token = await firebase.getToken();
      if (token != null) await _register(container, token);
      await _refresh?.cancel();
      _refresh = firebase.onTokenRefresh.listen(
        (value) => unawaited(_register(container, value)),
      );
      await _opened?.cancel();
      _opened = FirebaseMessaging.onMessageOpenedApp.listen(_openReading);
      final initial = await firebase.getInitialMessage();
      if (initial != null) _openReading(initial);
    } catch (_) {
      // Missing/stale token, denied permission, or platform failure is never
      // allowed to affect the reading lifecycle.
    }
  }

  static Future<void> _installWith(
    ReadingPushMessaging messaging,
    ProviderContainer container,
  ) async {
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token != null) await _register(container, token);
    await _refresh?.cancel();
    _refresh = messaging.onTokenRefresh.listen(
      (value) => unawaited(_register(container, value)),
    );
    await _opened?.cancel();
    _opened = messaging.onMessageOpenedApp.listen(_openReading);
    final initial = await messaging.getInitialMessage();
    if (initial != null) _openReading(initial);
  }

  static Future<void> _register(
    ProviderContainer container,
    String token,
  ) async {
    if (!AccountDeletionPendingState.allowsOwnerBoundExperience) return;
    final send = container.read(readingOperationSenderProvider);
    if (send == null) return;
    await send('POST', '/v1/reading-notifications/token', {'token': token});
  }

  static void _openReading(RemoteMessage message) {
    final destination = readingPushDestination(message.data);
    if (destination == null) return;
    // Preserve the exact completion even while deletion/integrity recovery
    // temporarily blocks owner-bound navigation. openPending() is the sole
    // gate that decides when it is safe to consume this queued target.
    // This matches share/general-notification inbox semantics and prevents a
    // valid Coffee/Palm completion tap from being lost during recovery.
    // Cold start may receive the initial FCM message while Splash is still
    // the root route. Pushing now would be erased by Splash's later
    // pushReplacement(Home). Keep the exact target until the live shell binds.
    _pendingDestination = destination;
    openPending();
  }

  /// Opens the latest tapped completion only after the live app shell exists.
  /// If navigation is not ready yet the destination stays queued.
  static void openPending() {
    if (!AccountDeletionPendingState.isClear ||
        !OraclyShellBridge.isActive) {
      return;
    }
    final destination = _pendingDestination;
    if (destination == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AccountDeletionPendingState.isClear ||
          !OraclyShellBridge.isActive) {
        return;
      }
      final current = _pendingDestination;
      if (current == null ||
          current.route != destination.route ||
          current.operationId != destination.operationId) {
        return;
      }
      final navigator = oraclyNavigatorKey.currentState;
      if (navigator == null) return;
      _pendingDestination = null;
      navigator.pushNamed(
        destination.route,
        arguments: {'operationId': destination.operationId},
      );
    });
  }

  @visibleForTesting
  static ReadingPushDestination? get pendingDestinationForTest =>
      _pendingDestination;

  @visibleForTesting
  static Future<void> cancelSubscriptionsForTest() async {
    await _refresh?.cancel();
    await _opened?.cancel();
    _refresh = null;
    _opened = null;
    _pendingDestination = null;
  }
}

final class ReadingPushDestination {
  const ReadingPushDestination({required this.route, required this.operationId});

  final String route;
  final String operationId;
}

/// Pure mapping kept independently testable from the Firebase platform
/// channel. The operation ID is carried into navigation while the screen's
/// normal recoverActive path reconciles the authoritative persisted result.
ReadingPushDestination? readingPushDestination(Map<String, dynamic> data) {
  if (data['type'] != 'reading_completed') return null;
  final operationId = data['operationId'];
  if (operationId is! String ||
      !RegExp(r'^[a-f0-9]{32}$').hasMatch(operationId)) {
    return null;
  }
  final route = switch (data['readingType']) {
    'coffee' => OraclyRoutes.coffee,
    'palm' => OraclyRoutes.palm,
    _ => null,
  };
  return route == null
      ? null
      : ReadingPushDestination(route: route, operationId: operationId);
}
