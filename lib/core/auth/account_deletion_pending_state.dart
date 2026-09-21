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
import 'account_deletion_target.dart';

enum AccountDeletionGatePhase {
  unresolved,
  clear,
  blocked,
  storageUnavailable,
  finalizing,
  /// A marker is present but of the WRONG TYPE (corrupt). This is UNKNOWN
  /// state — not evidence a deletion was ever requested or accepted. It
  /// blocks the same owner-bound surface as [blocked]/[finalizing] but must
  /// NEVER trigger [AccountDeletionService.retryPendingIdentityCleanup],
  /// identity deletion, local wipe, or anonymous-identity creation. Distinct
  /// from [blocked]/[finalizing], which mean a REAL deletion lifecycle is
  /// known to exist.
  integrityRecovery,
}

enum AccountDeletionGateResolveStatus {
  clear,
  blocked,
  finalizing,
  storageUnavailable,
  integrityRecovery,
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

  static bool get isIntegrityRecovery =>
      phase.value == AccountDeletionGatePhase.integrityRecovery;

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
  /// that resolution actually proved storage durable AND the markers read
  /// as trustworthy (not corrupt) — attempt one automatic finalization
  /// retry and re-derive the phase from its outcome.
  ///
  /// If resolution came back [AccountDeletionGateResolveStatus.storageUnavailable]
  /// or [AccountDeletionGateResolveStatus.integrityRecovery], this returns
  /// immediately without touching [deletion] at all: no marker read, no
  /// retry, no [applyFromMarkers] call. Re-reading the same two markers
  /// through the same untrustworthy (empty ephemeral, or corrupt) storage
  /// would either silently derive "clear" (overwriting the correct
  /// fail-closed result) or — worse — treat a corrupt marker as genuine
  /// pending-deletion evidence and trigger destructive work it was never
  /// authorized to trigger. [main] and any other real startup entry point
  /// call this one function instead of reimplementing the sequence inline,
  /// so there is exactly one place this guard can be forgotten.
  static Future<void> resolveAndReconcile(
    LocalStorage storage,
    AccountDeletionService deletion,
  ) async {
    final status = await resolveFromLocalStorage(storage);
    if (status == AccountDeletionGateResolveStatus.storageUnavailable) return;
    if (status == AccountDeletionGateResolveStatus.integrityRecovery) {
      // One specific integrityRecovery cause is provably harmless: nothing
      // is corrupt, no phase marker is (or ever was, per these exact
      // reads) durably true — only leftover target/bootstrap provenance
      // survived a crash that happened either before any destructive work
      // began, or after every destructive step had already fully
      // completed. Reconciling ONLY this proven-safe case avoids bricking
      // the app in integrityRecovery forever over a crash that never
      // authorized anything destructive; anything less certain (corrupt,
      // or a real phase marker still true) is deliberately left alone.
      if (!deletion.hasCorruptDeletionMarker &&
          !deletion.hasPendingFinalization &&
          (AccountDeletionTarget.hasValidTarget(storage) ||
              AccountDeletionTarget.readBootstrapUid(storage) != null ||
              AccountDeletionMarkers.isExactlyTrue(
                storage,
                'account_deletion_bootstrap_creation_armed',
              ))) {
        try {
          if (await AccountDeletionTarget.reconcileHarmlessOrphan(storage)) {
            phase.value = AccountDeletionGatePhase.clear;
          }
        } catch (_) {}
      }
      return;
    }
    try {
      // hasPendingFinalization is EXACT-true-only (never corrupt) — see
      // AccountDeletionService — so this can never retry a corrupt marker
      // even if reached with one somehow still present.
      if (deletion.hasPendingFinalization) {
        await deletion.retryPendingIdentityCleanup();
      }
      applyFromMarkers(
        serverDeletePending: deletion.hasPendingServerDelete,
        identityCleanupPending: deletion.hasPendingIdentityCleanup,
        localWipePending: deletion.hasPendingLocalWipe,
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

    final anonRead = AccountDeletionMarkers.read(
      storage,
      AccountDeletionService.pendingAnonymousBootstrapKey,
    );
    final identityRead = AccountDeletionMarkers.read(
      storage,
      AccountDeletionService.pendingIdentityCleanupKey,
    );
    final localWipeRead = AccountDeletionMarkers.read(
      storage,
      AccountDeletionService.pendingLocalWipeKey,
    );
    final serverDeleteRead = AccountDeletionMarkers.read(
      storage,
      AccountDeletionService.pendingServerDeleteKey,
    );

    if (anonRead == MarkerRead.corrupt ||
        identityRead == MarkerRead.corrupt ||
        localWipeRead == MarkerRead.corrupt ||
        serverDeleteRead == MarkerRead.corrupt ||
        AccountDeletionTarget.isTargetCorrupt(storage) ||
        AccountDeletionTarget.isBootstrapCorrupt(storage) ||
        AccountDeletionMarkers.read(
              storage,
              'account_deletion_bootstrap_creation_armed',
            ) ==
            MarkerRead.corrupt) {
      phase.value = AccountDeletionGatePhase.integrityRecovery;
      return AccountDeletionGateResolveStatus.integrityRecovery;
    }

    if (anonRead == MarkerRead.isTrue || localWipeRead == MarkerRead.isTrue) {
      phase.value = AccountDeletionGatePhase.finalizing;
      return AccountDeletionGateResolveStatus.finalizing;
    }

    if (identityRead == MarkerRead.isTrue ||
        serverDeleteRead == MarkerRead.isTrue) {
      phase.value = AccountDeletionGatePhase.blocked;
      return AccountDeletionGateResolveStatus.blocked;
    }

    // Every boolean phase marker is durably absent — but a target or
    // bootstrap provenance key surviving alone is never evidence of a
    // healthy clear device. It must be reconciled (see
    // AccountDeletionTarget.reconcileHarmlessOrphan, invoked only from
    // resolveAndReconcile) before this may ever read as clear again.
    if (AccountDeletionTarget.hasValidTarget(storage) ||
        AccountDeletionTarget.readBootstrapUid(storage) != null ||
        AccountDeletionMarkers.isExactlyTrue(
          storage,
          'account_deletion_bootstrap_creation_armed',
        )) {
      phase.value = AccountDeletionGatePhase.integrityRecovery;
      return AccountDeletionGateResolveStatus.integrityRecovery;
    }

    phase.value = AccountDeletionGatePhase.clear;
    return AccountDeletionGateResolveStatus.clear;
  }

  static void applyFromMarkers({
    bool serverDeletePending = false,
    required bool identityCleanupPending,
    required bool localWipePending,
    required bool anonymousBootstrapPending,
  }) {
    if (anonymousBootstrapPending || localWipePending) {
      phase.value = AccountDeletionGatePhase.finalizing;
      return;
    }
    if (identityCleanupPending || serverDeletePending) {
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

  static void markIntegrityRecovery() {
    phase.value = AccountDeletionGatePhase.integrityRecovery;
  }

  static void markClear() {
    phase.value = AccountDeletionGatePhase.clear;
  }

  /// Test helper — cold-start race simulations.
  @visibleForTesting
  static void resetForTest() {
    phase.value = AccountDeletionGatePhase.unresolved;
    _inFlightResolve = null;
  }
}
