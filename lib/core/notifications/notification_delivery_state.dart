/// Internal, production-safe view of whether ORACLY can actually notify.
///
/// Holds categories only — never a push token, payload body, theme label or
/// account identifier — so it is safe to log and to show in diagnostics.
///
/// Failures are owned by a domain (permission, schedule, push, test). A
/// domain's failure is cleared only when that same domain becomes healthy,
/// so a recovered subsystem never erases a still-current unrelated failure.
library;

import 'package:flutter/foundation.dart';

import 'notification_permission.dart';
import 'notification_timezone.dart';

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

enum NotificationFailureDomain { permission, schedule, push, test }

enum NotificationFailureCategory {
  permissionDenied(NotificationFailureDomain.permission),
  permissionPermanentlyDenied(NotificationFailureDomain.permission),
  permissionUnavailable(NotificationFailureDomain.permission),
  scheduleFailed(NotificationFailureDomain.schedule),
  scheduleNotConfirmed(NotificationFailureDomain.schedule),
  cancelFailed(NotificationFailureDomain.schedule),
  tokenUnavailable(NotificationFailureDomain.push),
  registrationNotConfigured(NotificationFailureDomain.push),
  registrationFailed(NotificationFailureDomain.push),
  testDeliveryFailed(NotificationFailureDomain.test);

  const NotificationFailureCategory(this.domain);

  final NotificationFailureDomain domain;
}

@immutable
class NotificationDeliveryState {
  const NotificationDeliveryState({
    this.permission,
    this.preferenceEnabled,
    this.push = PushRegistrationState.unknown,
    this.schedule = LocalScheduleState.unknown,
    this.timezone,
    this.activeFailures = const [],
  });

  /// Null until the OS has been asked in this process.
  final NotificationPermissionStatus? permission;

  /// Null until settings were applied in this process.
  final bool? preferenceEnabled;
  final PushRegistrationState push;
  final LocalScheduleState schedule;

  /// Null until the scheduling zone was resolved.
  final NotificationTimezoneSource? timezone;

  /// At most one current failure per domain, oldest first.
  final List<NotificationFailureCategory> activeFailures;

  /// Most recent failure that is still current, if any.
  NotificationFailureCategory? get lastFailure =>
      activeFailures.isEmpty ? null : activeFailures.last;

  NotificationFailureCategory? failureIn(NotificationFailureDomain domain) {
    for (final failure in activeFailures) {
      if (failure.domain == domain) return failure;
    }
    return null;
  }

  /// True only when every local-delivery precondition is proven.
  bool get localDeliveryReady =>
      (permission?.canDeliver ?? false) &&
      preferenceEnabled == true &&
      schedule == LocalScheduleState.scheduled;

  NotificationDeliveryState _with({
    NotificationPermissionStatus? permission,
    bool? preferenceEnabled,
    PushRegistrationState? push,
    LocalScheduleState? schedule,
    NotificationTimezoneSource? timezone,
    List<NotificationFailureCategory>? activeFailures,
  }) {
    return NotificationDeliveryState(
      permission: permission ?? this.permission,
      preferenceEnabled: preferenceEnabled ?? this.preferenceEnabled,
      push: push ?? this.push,
      schedule: schedule ?? this.schedule,
      timezone: timezone ?? this.timezone,
      activeFailures: activeFailures ?? this.activeFailures,
    );
  }

  /// Replaces the failure of [failure]'s domain (newest last).
  NotificationDeliveryState _fail(NotificationFailureCategory failure) =>
      _with(
        activeFailures: List.unmodifiable([
          for (final f in activeFailures)
            if (f.domain != failure.domain) f,
          failure,
        ]),
      );

  /// Clears only [domain]'s failure.
  NotificationDeliveryState _heal(NotificationFailureDomain domain) => _with(
    activeFailures: List.unmodifiable([
      for (final f in activeFailures)
        if (f.domain != domain) f,
    ]),
  );

  /// Category-only snapshot for logs/diagnostics.
  Map<String, String> toDiagnostics() => {
    'permission': permission?.name ?? 'unknown',
    'preference': preferenceEnabled == null
        ? 'unknown'
        : (preferenceEnabled! ? 'on' : 'off'),
    'push': push.name,
    'schedule': schedule.name,
    'timezone': timezone?.name ?? 'unknown',
    'lastFailure': lastFailure?.name ?? 'none',
    'activeFailures': activeFailures.isEmpty
        ? 'none'
        : activeFailures.map((f) => f.name).join(','),
  };

  @override
  bool operator ==(Object other) =>
      other is NotificationDeliveryState &&
      other.permission == permission &&
      other.preferenceEnabled == preferenceEnabled &&
      other.push == push &&
      other.schedule == schedule &&
      other.timezone == timezone &&
      listEquals(other.activeFailures, activeFailures);

  @override
  int get hashCode => Object.hash(
    permission,
    preferenceEnabled,
    push,
    schedule,
    timezone,
    Object.hashAll(activeFailures),
  );

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

  /// A real OS read. Deliverable clears a stale permission failure
  /// (including permanentlyDenied → granted after the user changed Settings).
  static void recordPermission(NotificationPermissionStatus status) {
    final failure = failureFor(status);
    final next = _state.value._with(permission: status);
    _state.value = failure == null
        ? next._heal(NotificationFailureDomain.permission)
        : next._fail(failure);
  }

  static void recordPreference(bool enabled) {
    _state.value = _state.value._with(preferenceEnabled: enabled);
  }

  static void recordTimezone(NotificationTimezoneSource source) {
    _state.value = _state.value._with(timezone: source);
  }

  /// [failure] must belong to the schedule domain. A failed schedule without
  /// an explicit category keeps a more precise current one, else records
  /// [NotificationFailureCategory.scheduleFailed]. scheduled/disabled are
  /// healthy and clear the schedule domain.
  static void recordSchedule(
    LocalScheduleState schedule, {
    NotificationFailureCategory? failure,
  }) {
    assert(
      failure == null || failure.domain == NotificationFailureDomain.schedule,
    );
    final next = _state.value._with(schedule: schedule);
    if (schedule == LocalScheduleState.failed) {
      final category =
          failure ??
          next.failureIn(NotificationFailureDomain.schedule) ??
          NotificationFailureCategory.scheduleFailed;
      _state.value = next._fail(category);
    } else if (schedule == LocalScheduleState.unknown) {
      _state.value = next;
    } else {
      _state.value = next._heal(NotificationFailureDomain.schedule);
    }
  }

  /// [failure] must belong to the push domain. registered/noOwner clear it.
  static void recordPush(
    PushRegistrationState push, {
    NotificationFailureCategory? failure,
  }) {
    assert(failure == null || failure.domain == NotificationFailureDomain.push);
    final next = _state.value._with(push: push);
    switch (push) {
      case PushRegistrationState.registered:
      case PushRegistrationState.noOwner:
        _state.value = next._heal(NotificationFailureDomain.push);
      case PushRegistrationState.unknown:
        _state.value = next;
      case PushRegistrationState.tokenUnavailable:
      case PushRegistrationState.notConfigured:
      case PushRegistrationState.failed:
        _state.value = next._fail(
          failure ??
              switch (push) {
                PushRegistrationState.tokenUnavailable =>
                  NotificationFailureCategory.tokenUnavailable,
                PushRegistrationState.notConfigured =>
                  NotificationFailureCategory.registrationNotConfigured,
                _ => NotificationFailureCategory.registrationFailed,
              },
        );
    }
  }

  static void recordTestDelivery({required bool delivered}) {
    _state.value = delivered
        ? _state.value._heal(NotificationFailureDomain.test)
        : _state.value._fail(NotificationFailureCategory.testDeliveryFailed);
  }

  static void recordFailure(NotificationFailureCategory failure) {
    _state.value = _state.value._fail(failure);
  }

  /// Account boundary (sign-out, switch, deletion): owner-bound facts and
  /// their failures are dropped. OS permission and the timezone are
  /// device-wide and stay, with their current permission failure.
  static void resetForOwnerBoundary() {
    final current = _state.value;
    final permissionFailure = current.failureIn(
      NotificationFailureDomain.permission,
    );
    _state.value = NotificationDeliveryState(
      permission: current.permission,
      push: PushRegistrationState.noOwner,
      timezone: current.timezone,
      activeFailures: permissionFailure == null
          ? const []
          : List.unmodifiable([permissionFailure]),
    );
  }

  @visibleForTesting
  static void resetForTest() {
    _state.value = const NotificationDeliveryState();
  }
}
