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

  static Future<ApiResult<bool>> finishAfterIdentityDeleted({
    required AuthService auth,
    required LocalStorage storage,
    required SecureStorage secureStorage,
    required String identityCleanupKey,
  }) async {
    await UserLocalDataWipe.run(storage, secureStorage: secureStorage);
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
