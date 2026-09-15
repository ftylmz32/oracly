/// Post–sign-out account-boundary cleanup — wipe disk, then refresh providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/privacy/services/privacy_data_refresh.dart';
import '../data/datasources/local_storage.dart';
import '../storage/secure_storage.dart';
import 'user_local_data_isolation.dart';
import 'user_local_data_wipe.dart';

/// R5 — call only after auth sign-out succeeds. Never deletes server records.
abstract final class SignOutLocalCleanup {
  SignOutLocalCleanup._();

  /// Disk wipe + provider refresh. Prefer [wipeDiskOnly] then UI, then
  /// [refreshProviders] when a success snackbar must survive rebuilds.
  static Future<void> afterSuccessfulSignOut({
    required LocalStorage storage,
    required SecureStorage secureStorage,
    required WidgetRef ref,
  }) async {
    await wipeDiskOnly(storage: storage, secureStorage: secureStorage);
    refreshProviders(ref);
  }

  /// Testable path without [WidgetRef] — disk + owner/epoch only.
  static Future<void> wipeDiskOnly({
    required LocalStorage storage,
    required SecureStorage secureStorage,
  }) async {
    try {
      await UserLocalDataWipe.run(storage, secureStorage: secureStorage);
      await storage.remove(UserLocalDataIsolation.ownerKey);
      UserLocalDataIsolation.accountSwitchEpoch.value++;
    } catch (_) {
      // Persist best-effort; callers still invalidate in-memory state.
    }
  }

  static void refreshProviders(WidgetRef ref) {
    try {
      PrivacyDataRefresh.afterAccountSwitch(ref);
    } catch (_) {
      // In-memory refresh must not undo a successful auth sign-out.
    }
  }
}
