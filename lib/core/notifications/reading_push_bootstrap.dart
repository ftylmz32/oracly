/// Completion-only Firebase Messaging bootstrap for durable Coffee/Palm jobs.
library;

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/reading_operation/providers/reading_live_provider.dart';
import '../auth/account_deletion_pending_state.dart';
import '../navigation/oracly_navigator_key.dart';
import '../navigation/oracly_routes.dart';
import '../providers/backend_providers.dart';
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
  static String? _installedOwnerId;

  @visibleForTesting
  static ReadingPushMessaging? messagingForTest;

  @visibleForTesting
  static String? installedOwnerIdForTest;

  static Future<void> install(ProviderContainer container) async {
    if (!AccountDeletionPendingState.allowsOwnerBoundExperience) return;
    final nextOwnerId =
        installedOwnerIdForTest ??
        container.read(firebaseAuthUserProvider).valueOrNull?.uid ??
        container.read(firebaseAuthGatewayProvider)?.currentUser?.uid;
    _bindOwner(nextOwnerId);
    if (_installedOwnerId == null) {
      await clearOwnerBinding();
      return;
    }
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
      final listenerOwner = _installedOwnerId;
      _opened = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _openReading(message, expectedOwner: listenerOwner),
      );
      final initial = await firebase.getInitialMessage();
      if (initial != null) {
        _openReading(initial, expectedOwner: listenerOwner);
      }
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
    final listenerOwner = _installedOwnerId;
    _opened = messaging.onMessageOpenedApp.listen(
      (message) => _openReading(message, expectedOwner: listenerOwner),
    );
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _openReading(initial, expectedOwner: listenerOwner);
    }
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

  static void _openReading(
    RemoteMessage message, {
    required String? expectedOwner,
  }) {
    final owner = _installedOwnerId;
    if (owner == null || owner.isEmpty) return;
    // Listener generations are account-bound. An event delivered by an old
    // subscription during A→B handoff must never be relabeled as B merely
    // because B became current before cancellation completed.
    if (expectedOwner == null || expectedOwner != owner) return;
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
    _pendingDestination = ReadingPushDestination(
      route: destination.route,
      operationId: destination.operationId,
      ownerId: owner,
    );
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

    final ownerAtInstall = _installedOwnerId;
    final destinationOwner = destination.ownerId;
    if (destinationOwner != null &&
        ownerAtInstall != null &&
        destinationOwner != ownerAtInstall) {
      _pendingDestination = null;
      return;
    }

    // If the live root navigator is ready, consume immediately. Waiting one
    // extra frame made gate-clear drains fragile and served no safety purpose;
    // when the navigator is not ready we simply keep the exact destination
    // queued for the shell's next openPending() call.
    final navigator = oraclyNavigatorKey.currentState;
    if (navigator == null) return;

    final current = _pendingDestination;
    if (current == null ||
        current.route != destination.route ||
        current.operationId != destination.operationId ||
        current.ownerId != destination.ownerId) {
      return;
    }

    try {
      navigator.pushNamed(
        destination.route,
        arguments: {'operationId': destination.operationId},
      );
      _pendingDestination = null;
    } catch (_) {
      // Keep the destination queued if route construction/navigation throws.
    }
  }

  static void _bindOwner(String? ownerId) {
    final normalized = ownerId?.trim();
    final next = normalized == null || normalized.isEmpty ? null : normalized;
    final pending = _pendingDestination;
    if (next == null ||
        (pending?.ownerId != null && pending!.ownerId != next)) {
      // Account boundary: never retain a queued completion once there is no
      // authenticated owner, or when a different owner becomes current.
      _pendingDestination = null;
    }
    _installedOwnerId = next;
  }

  /// Successful sign-out boundary. Stops old-owner listeners and drops any
  /// queued completion before local/provider cleanup proceeds.
  static Future<void> clearOwnerBinding() async {
    _bindOwner(null);
    await _refresh?.cancel();
    await _opened?.cancel();
    _refresh = null;
    _opened = null;
  }

  @visibleForTesting
  static void bindOwnerForTest(String? ownerId) => _bindOwner(ownerId);

  @visibleForTesting
  static String? get installedOwnerForTest => _installedOwnerId;

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
    _installedOwnerId = null;
    installedOwnerIdForTest = null;
  }
}

final class ReadingPushDestination {
  const ReadingPushDestination({
    required this.route,
    required this.operationId,
    this.ownerId,
  });

  final String route;
  final String operationId;
  final String? ownerId;
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
