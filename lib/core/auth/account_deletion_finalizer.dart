/// Anonymous-session finalization after the old identity is gone.
library;

import '../data/datasources/local_storage.dart';
import '../network/api_result.dart';
import '../network/network_exception.dart';
import '../storage/secure_storage.dart';
import 'account_deletion_pending_state.dart';
import 'auth_copy.dart';
import 'auth_service.dart';
import 'user_local_data_isolation.dart';
import 'user_local_data_wipe.dart';

abstract final class AccountDeletionFinalizer {
  AccountDeletionFinalizer._();

  static const anonymousBootstrapKey =
      'account_deletion_pending_anonymous_bootstrap';

  /// Set when the Firebase identity IS confirmed deleted but the LOCAL
  /// account-scoped wipe did not fully succeed. Distinct from
  /// [AccountDeletionService.pendingIdentityCleanupKey] (which means the
  /// Firebase identity itself still needs deleting) — conflating the two
  /// would risk a retry re-attempting [AuthService.deleteAccount] on an
  /// identity that is already gone. A retry while this is set must
  /// re-attempt ONLY the local wipe.
  static const localWipePendingKey = 'account_deletion_pending_local_wipe';

  static Future<ApiResult<bool>> finishAfterIdentityDeleted({
    required AuthService auth,
    required LocalStorage storage,
    required SecureStorage secureStorage,
    required String identityCleanupKey,
  }) async {
    final wipeResult = await UserLocalDataWipe.run(
      storage,
      secureStorage: secureStorage,
    );
    if (!wipeResult.isComplete) {
      // The identity is gone — that concern is genuinely resolved, so
      // identityCleanupKey is cleared (a retry must never re-attempt
      // deleteAccount on an already-deleted identity). But local
      // account-scoped cleanup did not fully succeed, so the deleted
      // owner's residue may still be on disk: stay finalizing, keep
      // ownerKey exactly as it was (still sufficient to force another
      // wipe attempt), and never proceed to bootstrap — let alone
      // expose — a "clear" anonymous owner over that residue.
      await storage.remove(identityCleanupKey);
      await storage.setBool(localWipePendingKey, true);
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    await storage.remove(localWipePendingKey);
    await storage.remove(UserLocalDataIsolation.ownerKey);
    await storage.remove(identityCleanupKey);
    await storage.setBool(anonymousBootstrapKey, true);
    AccountDeletionPendingState.markFinalizing();
    return completeAnonymousBootstrap(
      auth: auth,
      storage: storage,
      identityCleanupKey: identityCleanupKey,
    );
  }

  /// Never calls [AuthService.deleteAccount] — preserves a partial anon user.
  static Future<ApiResult<bool>> completeAnonymousBootstrap({
    required AuthService auth,
    required LocalStorage storage,
    required String identityCleanupKey,
  }) async {
    await storage.setBool(anonymousBootstrapKey, true);
    AccountDeletionPendingState.markFinalizing();

    final session = await auth.ensureAnonymousSession();
    if (session.isFailure) {
      return ApiFailure(
        session.errorOrNull ??
            NetworkException.unauthorized(AuthCopy.failed),
      );
    }

    // AuthService.ensureAnonymousSession reuses whatever current user
    // already exists — it does not itself guarantee that user is anonymous.
    // Positively prove the replacement identity before clearing the gate;
    // an unexpectedly linked/non-anonymous current user must stay
    // finalizing rather than have this silently declare success for an
    // identity that was never actually re-bootstrapped as anonymous.
    if (!auth.hasCurrentIdentity || !auth.isCurrentUserAnonymous) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }

    await storage.remove(anonymousBootstrapKey);
    await storage.remove(identityCleanupKey);
    AccountDeletionPendingState.markClear();
    UserLocalDataIsolation.accountSwitchEpoch.value++;
    return const ApiSuccess(true);
  }
}
