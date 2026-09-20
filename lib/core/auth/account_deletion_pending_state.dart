/// Startup gate for interrupted account deletion cleanup.
///
/// Production [main] calls [beginStartup] so the phase is [unresolved] before
/// the first frame. Routing-critical local storage then resolves to [clear] or
/// [blocked] before any owner-bound destination may mount.
///
/// The notifier defaults to [clear] so unit tests that never touch splash/main
/// keep generating normal routes. Race tests call [beginStartup] explicitly.
///
/// [blocked] means: server deletion already accepted; Firebase identity and/or
/// local wipe still incomplete. Only [AccountDeletionPendingScreen] may mount.
library;

import 'package:flutter/foundation.dart';

import '../data/datasources/local_storage.dart';
import 'account_deletion_service.dart';

enum AccountDeletionGatePhase {
  unresolved,
  clear,
  blocked,
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

  /// Owner-bound UI, gem hydrate, deep links, and anonymous bootstrap.
  static bool get allowsOwnerBoundExperience => isClear;

  /// Fail-closed while unresolved or blocked.
  static bool get blocksDeepLinks => !isClear;

  /// Call from production [main] before [runApp] — never from feature code.
  static void beginStartup() {
    phase.value = AccountDeletionGatePhase.unresolved;
  }

  /// Promote durable prefs if needed, then read the pending marker.
  /// Does not wait on network, App Check, gems, notifications, or analytics.
  static Future<void> resolveFromLocalStorage(LocalStorage storage) async {
    if (storage.isEphemeral) {
      await storage.tryPromote();
    }
    applyFromMarker(
      storage.getBool(AccountDeletionService.pendingIdentityCleanupKey) ??
          false,
    );
  }

  static void applyFromMarker(bool pending) {
    phase.value = pending
        ? AccountDeletionGatePhase.blocked
        : AccountDeletionGatePhase.clear;
  }

  static void markBlocked() {
    phase.value = AccountDeletionGatePhase.blocked;
  }

  static void markClear() {
    phase.value = AccountDeletionGatePhase.clear;
  }

  /// Test helper — returns to unresolved (cold-start race simulations).
  @visibleForTesting
  static void resetForTest() {
    phase.value = AccountDeletionGatePhase.unresolved;
  }
}
