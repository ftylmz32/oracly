/// Startup gate for interrupted account deletion / durable storage readiness.
///
/// Production [main] calls [beginStartup] so the phase is [unresolved] before
/// the first frame. Routing-critical local storage then resolves to a proven
/// phase before any owner-bound destination may mount.
///
/// [clear] means durable storage WAS successfully read AND no deletion
/// finalization markers remain. It never means "storage read failed".
///
/// The notifier defaults to [clear] so unit tests that never touch splash/main
/// keep generating normal routes. Race tests call [beginStartup] explicitly.
library;

import 'package:flutter/foundation.dart';

import '../data/datasources/local_storage.dart';
import 'account_deletion_markers.dart';
import 'account_deletion_service.dart';

enum AccountDeletionGatePhase {
  unresolved,
  clear,
  blocked,
  storageUnavailable,
  finalizing,
}

enum AccountDeletionGateResolveStatus {
  clear,
  blocked,
  finalizing,
  storageUnavailable,
}

abstract final class AccountDeletionPendingState {
  AccountDeletionPendingState._();

  /// Defaults to [clear] for isolated unit tests; production calls [beginStartup].
  static final ValueNotifier<AccountDeletionGatePhase> phase =
      ValueNotifier<AccountDeletionGatePhase>(AccountDeletionGatePhase.clear);

  static bool get isUnresolved =>
      phase.value == AccountDeletionGatePhase.unresolved;

  static bool get isClear => phase.value == AccountDeletionGatePhase.clear;

  static bool get isBlocked => phase.value == AccountDeletionGatePhase.blocked;

  static bool get isStorageUnavailable =>
      phase.value == AccountDeletionGatePhase.storageUnavailable;

  static bool get isFinalizing =>
      phase.value == AccountDeletionGatePhase.finalizing;

  /// Owner-bound UI, gem hydrate, deep links, push, and premium warm.
  static bool get allowsOwnerBoundExperience => isClear;

  /// Fail-closed for every non-clear phase.
  static bool get blocksDeepLinks => !isClear;

  /// Call from production [main] before [runApp] — never from feature code.
  static void beginStartup() {
    phase.value = AccountDeletionGatePhase.unresolved;
  }

  /// Single-flight guard — [main] and [SplashEntryBootstrap] (splash race,
  /// see splash_entry_bootstrap.dart) both call [resolveFromLocalStorage]
  /// independently. A concurrent second caller awaits the first's own
  /// in-progress resolution instead of racing a separate promotion/read
  /// against the same storage instance.
  static Future<AccountDeletionGateResolveStatus>? _inFlightResolve;

  /// Promote durable prefs if needed, then read deletion markers.
  /// Never treats a failed durable read as "no pending deletion".
  static Future<AccountDeletionGateResolveStatus> resolveFromLocalStorage(
    LocalStorage storage,
  ) {
    final existing = _inFlightResolve;
    if (existing != null) return existing;
    final future = _resolveFromLocalStorage(storage);
    _inFlightResolve = future;
    future.whenComplete(() => _inFlightResolve = null);
    return future;
  }

  /// THE real startup sequence: resolve durable storage, then — ONLY if
  /// that resolution actually proved storage durable — attempt one
  /// automatic finalization retry and re-derive the phase from its outcome.
  ///
  /// If resolution came back [AccountDeletionGateResolveStatus.storageUnavailable],
  /// this returns immediately without touching [deletion] at all: no marker
  /// read, no retry, no [applyFromMarkers] call. Re-reading the same two
  /// markers through the same untrustworthy (empty ephemeral) storage would
  /// see no keys and silently derive "clear", overwriting the correct
  /// fail-closed result. [main] and any other real startup entry point call
  /// this one function instead of reimplementing the sequence inline, so
  /// there is exactly one place this guard can be forgotten.
  static Future<void> resolveAndReconcile(
    LocalStorage storage,
    AccountDeletionService deletion,
  ) async {
    await resolveFromLocalStorage(storage);
    if (isStorageUnavailable) return;
    try {
      if (deletion.hasPendingFinalization) {
        await deletion.retryPendingIdentityCleanup();
      }
      applyFromMarkers(
        identityCleanupPending: deletion.hasPendingIdentityCleanup,
        anonymousBootstrapPending: deletion.hasPendingAnonymousBootstrap,
      );
    } catch (_) {}
  }

  static Future<AccountDeletionGateResolveStatus> _resolveFromLocalStorage(
    LocalStorage storage,
  ) async {
    if (storage.isEphemeral) {
      final promoted = await storage.tryPromote();
      if (!promoted || storage.isEphemeral) {
        phase.value = AccountDeletionGatePhase.storageUnavailable;
        return AccountDeletionGateResolveStatus.storageUnavailable;
      }
    }

    // A corrupt (wrong-type) marker counts as pending — never as "absent".
    // See AccountDeletionMarkers.
    final anonPending = AccountDeletionMarkers.isPendingOrCorrupt(
      storage,
      AccountDeletionService.pendingAnonymousBootstrapKey,
    );
    if (anonPending) {
      phase.value = AccountDeletionGatePhase.finalizing;
      return AccountDeletionGateResolveStatus.finalizing;
    }

    final identityPending = AccountDeletionMarkers.isPendingOrCorrupt(
      storage,
      AccountDeletionService.pendingIdentityCleanupKey,
    );
    if (identityPending) {
      phase.value = AccountDeletionGatePhase.blocked;
      return AccountDeletionGateResolveStatus.blocked;
    }

    phase.value = AccountDeletionGatePhase.clear;
    return AccountDeletionGateResolveStatus.clear;
  }

  static void applyFromMarkers({
    required bool identityCleanupPending,
    required bool anonymousBootstrapPending,
  }) {
    if (anonymousBootstrapPending) {
      phase.value = AccountDeletionGatePhase.finalizing;
      return;
    }
    if (identityCleanupPending) {
      phase.value = AccountDeletionGatePhase.blocked;
      return;
    }
    phase.value = AccountDeletionGatePhase.clear;
  }

  static void markBlocked() {
    phase.value = AccountDeletionGatePhase.blocked;
  }

  static void markFinalizing() {
    phase.value = AccountDeletionGatePhase.finalizing;
  }

  static void markStorageUnavailable() {
    phase.value = AccountDeletionGatePhase.storageUnavailable;
  }

  static void markClear() {
    phase.value = AccountDeletionGatePhase.clear;
  }

  /// Test helper — cold-start race simulations.
  @visibleForTesting
  static void resetForTest() {
    phase.value = AccountDeletionGatePhase.unresolved;
  }
}
