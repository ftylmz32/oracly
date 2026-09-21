/// One typed mapping from deletion-gate state to what a route surface must
/// show — the single place "which screen for which state" is decided, so
/// no route surface (SplashDestination, OraclyRouteGenerator,
/// MaterialApp.onUnknownRoute, the recovery router) can invent its own
/// interpretation and drift from the others. This exact class of bug —
/// storageUnavailable/unresolved wrongly falling through to the
/// pending-deletion screen's "a deletion is pending" copy — has already
/// happened once; routing through one mapper makes it structurally
/// impossible for a new surface to repeat it.
library;

import 'account_deletion_pending_state.dart';

enum AccountDeletionGateDestination {
  /// clear — no override; the caller proceeds with whatever route was
  /// actually requested.
  normalRoute,

  /// blocked/finalizing — a REAL deletion lifecycle is known to exist.
  pendingDeletion,

  /// A marker is present but corrupt (wrong type) — UNKNOWN state, never
  /// evidence a deletion was requested or accepted. Must NEVER show the
  /// pending-deletion copy.
  integrityRecovery,

  /// Durable storage could not be opened — not deletion-related at all.
  storageUnavailable,

  /// Gate not yet resolved. Must NOT claim anything about deletion state —
  /// neutral/brand-safe only, never the pending-deletion copy.
  unresolved,
}

abstract final class AccountDeletionGateDestinations {
  AccountDeletionGateDestinations._();

  static AccountDeletionGateDestination forPhase(
    AccountDeletionGatePhase phase,
  ) {
    return switch (phase) {
      AccountDeletionGatePhase.clear =>
        AccountDeletionGateDestination.normalRoute,
      AccountDeletionGatePhase.blocked ||
      AccountDeletionGatePhase.finalizing =>
        AccountDeletionGateDestination.pendingDeletion,
      AccountDeletionGatePhase.integrityRecovery =>
        AccountDeletionGateDestination.integrityRecovery,
      AccountDeletionGatePhase.storageUnavailable =>
        AccountDeletionGateDestination.storageUnavailable,
      AccountDeletionGatePhase.unresolved =>
        AccountDeletionGateDestination.unresolved,
    };
  }

  static AccountDeletionGateDestination forResolveStatus(
    AccountDeletionGateResolveStatus status,
  ) {
    return switch (status) {
      AccountDeletionGateResolveStatus.clear =>
        AccountDeletionGateDestination.normalRoute,
      AccountDeletionGateResolveStatus.blocked ||
      AccountDeletionGateResolveStatus.finalizing =>
        AccountDeletionGateDestination.pendingDeletion,
      AccountDeletionGateResolveStatus.integrityRecovery =>
        AccountDeletionGateDestination.integrityRecovery,
      AccountDeletionGateResolveStatus.storageUnavailable =>
        AccountDeletionGateDestination.storageUnavailable,
    };
  }

  /// Convenience for the current global phase.
  static AccountDeletionGateDestination get current =>
      forPhase(AccountDeletionPendingState.phase.value);
}
