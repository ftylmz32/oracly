/// Post–sign-out account-boundary cleanup — wipe disk, then refresh providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/privacy/services/privacy_data_refresh.dart';
import '../data/datasources/local_storage.dart';
import '../storage/secure_storage.dart';
import 'user_local_data_isolation.dart';
import 'user_local_data_wipe.dart';
import 'user_local_data_wipe_result.dart';

/// R5 — call only after auth sign-out succeeds. Never deletes server records.
abstract final class SignOutLocalCleanup {
  SignOutLocalCleanup._();

  /// Disk wipe + provider refresh. Prefer [wipeDiskOnly] then UI, then
  /// [refreshProviders] when a success snackbar must survive rebuilds.
  static Future<UserLocalDataWipeResult> afterSuccessfulSignOut({
    required LocalStorage storage,
    required SecureStorage secureStorage,
    required WidgetRef ref,
  }) async {
    final result = await wipeDiskOnly(
      storage: storage,
      secureStorage: secureStorage,
    );
    refreshProviders(ref);
    return result;
  }

  /// Testable path without [WidgetRef] — disk + owner/epoch only.
  ///
  /// AUTH SIGNED OUT and LOCAL PRIVACY CLEANUP COMPLETE are two different
  /// facts: Firebase sign-out has already succeeded by the time a caller
  /// reaches this (that is this function's precondition), so this never
  /// pretends sign-out itself failed. What it DOES report honestly is
  /// whether the local wipe fully succeeded:
  /// - complete: [UserLocalDataIsolation.ownerKey] is removed and
  ///   [UserLocalDataIsolation.accountSwitchEpoch] bumps — this device now
  ///   has no local owner until someone signs in again.
  /// - incomplete: [UserLocalDataIsolation.ownerKey] is deliberately left
  ///   as-is (the just-signed-out user's uid) — that stale marker is what
  ///   forces [UserLocalDataIsolation.onSignedIn] to retry the wipe before
  ///   treating ANY next distinct sign-in as isolated, so leftover data is
  ///   never silently handed to a new owner as if it were their own.
  static Future<UserLocalDataWipeResult> wipeDiskOnly({
    required LocalStorage storage,
    required SecureStorage secureStorage,
  }) async {
    final result = await UserLocalDataWipe.run(
      storage,
      secureStorage: secureStorage,
    );
    if (!result.isComplete) return result;
    // A `false` (non-throwing) removal is exactly as much a failure here
    // as a thrown one: either way ownerKey would still show the just-
    // signed-out uid, which is what forces UserLocalDataIsolation to
    // retry on the next sign-in rather than silently treating leftover
    // data as already isolated. The epoch must not bump, and the caller
    // must not be told cleanup is complete, unless ownerKey's removal is
    // actually proven durable.
    bool ownerKeyRemoved;
    try {
      ownerKeyRemoved = await storage.remove(UserLocalDataIsolation.ownerKey);
    } catch (_) {
      ownerKeyRemoved = false;
    }
    if (!ownerKeyRemoved) {
      return UserLocalDataWipeResult(
        failedOperations: [
          ...result.failedOperations,
          UserLocalDataIsolation.ownerKey,
        ],
      );
    }
    UserLocalDataIsolation.accountSwitchEpoch.value++;
    return result;
  }

  static void refreshProviders(WidgetRef ref) {
    try {
      PrivacyDataRefresh.afterAccountSwitch(ref);
    } catch (_) {
      // In-memory refresh must not undo a successful auth sign-out.
    }
  }
}
