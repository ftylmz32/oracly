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
    if (!AccountDeletionPendingState.isClear) return;
    final destination = readingPushDestination(message.data);
    if (destination == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oraclyNavigatorKey.currentState?.pushNamed(
        destination.route,
        arguments: {'operationId': destination.operationId},
      );
    });
  }

  @visibleForTesting
  static Future<void> cancelSubscriptionsForTest() async {
    await _refresh?.cancel();
    await _opened?.cancel();
    _refresh = null;
    _opened = null;
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
      !RegExp(r'^[a-f0-9]{32}  final route = switch (data['readingType']) {
    'coffee' => OraclyRoutes.coffee,
    'palm' => OraclyRoutes.palm,
    _ => null,
  };
  return route == null
      ? null
      : ReadingPushDestination(route: route, operationId: operationId);
}
).hasMatch(operationId)) {
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
