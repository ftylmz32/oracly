/// Internal, production-safe view of whether ORACLY can actually notify.
///
/// Holds categories only — never a push token, payload body, theme label or
/// account identifier — so it is safe to log and to show in diagnostics.
library;

import 'package:flutter/foundation.dart';

import 'notification_permission.dart';

enum PushRegistrationState {
  /// Nothing attempted yet in this process.
  unknown,

  /// No authenticated owner — nothing may be registered.
  noOwner,

  /// The platform returned no push token (e.g. APNs not available).
  tokenUnavailable,

  /// The backend sender is not configured in this build.
  notConfigured,

  /// The backend accepted the current token for the current owner.
  registered,

  /// Registration was attempted and failed.
  failed,
}

enum LocalScheduleState {
  unknown,

  /// The app preference is off, so nothing is scheduled (by design).
  disabled,

  /// The OS confirmed the daily notification is pending.
  scheduled,

  /// Scheduling was attempted and is not in effect.
  failed,
}

enum NotificationFailureCategory {
  permissionDenied,
  permissionPermanentlyDenied,
  permissionUnavailable,
  scheduleFailed,
  scheduleNotConfirmed,
  cancelFailed,
  testDeliveryFailed,
  tokenUnavailable,
  registrationNotConfigured,
  registrationFailed,
}

@immutable
class NotificationDeliveryState {
  const NotificationDeliveryState({
    this.permission,
    this.preferenceEnabled,
    this.push = PushRegistrationState.unknown,
    this.schedule = LocalScheduleState.unknown,
    this.lastFailure,
  });

  /// Null until the OS has been asked in this process.
  final NotificationPermissionStatus? permission;

  /// Null until settings were applied in this process.
  final bool? preferenceEnabled;
  final PushRegistrationState push;
  final LocalScheduleState schedule;
  final NotificationFailureCategory? lastFailure;

  /// True only when every local-delivery precondition is proven.
  bool get localDeliveryReady =>
      (permission?.canDeliver ?? false) &&
      preferenceEnabled == true &&
      schedule == LocalScheduleState.scheduled;

  NotificationDeliveryState copyWith({
    NotificationPermissionStatus? permission,
    bool? preferenceEnabled,
    PushRegistrationState? push,
    LocalScheduleState? schedule,
    NotificationFailureCategory? lastFailure,
    bool clearFailure = false,
  }) {
    return NotificationDeliveryState(
      permission: permission ?? this.permission,
      preferenceEnabled: preferenceEnabled ?? this.preferenceEnabled,
      push: push ?? this.push,
      schedule: schedule ?? this.schedule,
      lastFailure: clearFailure ? null : (lastFailure ?? this.lastFailure),
    );
  }

  /// Category-only snapshot for logs/diagnostics.
  Map<String, String> toDiagnostics() => {
    'permission': permission?.name ?? 'unknown',
    'preference': preferenceEnabled == null
        ? 'unknown'
        : (preferenceEnabled! ? 'on' : 'off'),
    'push': push.name,
    'schedule': schedule.name,
    'lastFailure': lastFailure?.name ?? 'none',
  };

  @override
  bool operator ==(Object other) =>
      other is NotificationDeliveryState &&
      other.permission == permission &&
      other.preferenceEnabled == preferenceEnabled &&
      other.push == push &&
      other.schedule == schedule &&
      other.lastFailure == lastFailure;

  @override
  int get hashCode =>
      Object.hash(permission, preferenceEnabled, push, schedule, lastFailure);

  @override
  String toString() => 'NotificationDeliveryState(${toDiagnostics()})';
}

/// Process-wide recorder. Observable through [listenable].
abstract final class NotificationDeliveryStatus {
  NotificationDeliveryStatus._();

  static final ValueNotifier<NotificationDeliveryState> _state = ValueNotifier(
    const NotificationDeliveryState(),
  );

  static ValueListenable<NotificationDeliveryState> get listenable => _state;

  static NotificationDeliveryState get current => _state.value;

  static NotificationFailureCategory? failureFor(
    NotificationPermissionStatus status,
  ) {
    return switch (status) {
      NotificationPermissionStatus.granted ||
      NotificationPermissionStatus.provisional => null,
      NotificationPermissionStatus.permanentlyDenied =>
        NotificationFailureCategory.permissionPermanentlyDenied,
      NotificationPermissionStatus.unavailable =>
        NotificationFailureCategory.permissionUnavailable,
      NotificationPermissionStatus.notDetermined ||
      NotificationPermissionStatus.denied =>
        NotificationFailureCategory.permissionDenied,
    };
  }

  static void recordPermission(NotificationPermissionStatus status) {
    final failure = failureFor(status);
    _state.value = failure == null
        ? _state.value.copyWith(permission: status)
        : _state.value.copyWith(permission: status, lastFailure: failure);
  }

  static void recordPreference(bool enabled) {
    _state.value = _state.value.copyWith(preferenceEnabled: enabled);
  }

  static void recordSchedule(
    LocalScheduleState schedule, {
    NotificationFailureCategory? failure,
  }) {
    _state.value = _state.value.copyWith(
      schedule: schedule,
      lastFailure: failure,
    );
  }

  static void recordPush(
    PushRegistrationState push, {
    NotificationFailureCategory? failure,
  }) {
    _state.value = _state.value.copyWith(push: push, lastFailure: failure);
  }

  static void recordFailure(NotificationFailureCategory failure) {
    _state.value = _state.value.copyWith(lastFailure: failure);
  }

  /// Account boundary (sign-out, switch, deletion): owner-bound facts are
  /// dropped. OS permission is device-wide and stays.
  static void resetForOwnerBoundary() {
    _state.value = NotificationDeliveryState(
      permission: _state.value.permission,
      push: PushRegistrationState.noOwner,
    );
  }

  @visibleForTesting
  static void resetForTest() {
    _state.value = const NotificationDeliveryState();
  }
}
