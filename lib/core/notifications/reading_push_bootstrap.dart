/// Completion-only Firebase Messaging bootstrap for durable Coffee/Palm jobs.
library;

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/reading_operation/providers/reading_live_provider.dart';
import '../navigation/oracly_navigator_key.dart';
import '../navigation/oracly_routes.dart';

abstract final class ReadingPushBootstrap {
  ReadingPushBootstrap._();

  static StreamSubscription<String>? _refresh;
  static StreamSubscription<RemoteMessage>? _opened;

  static Future<void> install(ProviderContainer container) async {
    try {
      final messaging = FirebaseMessaging.instance;
      // Denial is a supported state and never affects reading completion.
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null) await _register(container, token);
      await _refresh?.cancel();
      _refresh = messaging.onTokenRefresh.listen(
        (value) => unawaited(_register(container, value)),
      );
      await _opened?.cancel();
      _opened = FirebaseMessaging.onMessageOpenedApp.listen(_openReading);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _openReading(initial);
    } catch (_) {
      // Missing/stale token, denied permission, or platform failure is never
      // allowed to affect the reading lifecycle.
    }
  }

  static Future<void> _register(ProviderContainer container, String token) async {
    final send = container.read(readingOperationSenderProvider);
    if (send == null) return;
    await send('POST', '/v1/reading-notifications/token', {'token': token});
  }

  static void _openReading(RemoteMessage message) {
    final destination = readingPushDestination(message.data);
    if (destination == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oraclyNavigatorKey.currentState?.pushNamed(
        destination.route,
        arguments: {'operationId': destination.operationId},
      );
    });
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
  if (operationId is! String || operationId.length != 32) return null;
  final route = switch (data['readingType']) {
    'coffee' => OraclyRoutes.coffee,
    'palm' => OraclyRoutes.palm,
    _ => null,
  };
  return route == null
      ? null
      : ReadingPushDestination(route: route, operationId: operationId);
}
