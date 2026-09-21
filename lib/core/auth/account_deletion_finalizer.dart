/// Anonymous-session finalization after the old identity is gone.
library;

import '../data/datasources/local_storage.dart';
import '../data/datasources/storage_result.dart';
import '../network/api_result.dart';
import '../network/network_exception.dart';
import '../storage/secure_storage.dart';
import 'account_deletion_markers.dart';
import 'account_deletion_pending_state.dart';
import 'account_deletion_target.dart';
import 'auth_copy.dart';
import 'auth_service.dart';
import 'user_local_data_isolation.dart';
import 'user_local_data_wipe.dart';

abstract final class AccountDeletionFinalizer {
  AccountDeletionFinalizer._();

  static const anonymousBootstrapKey =
      'account_deletion_pending_anonymous_bootstrap';
  static const serverDeletePendingKey =
      'account_deletion_pending_server_delete';
  static const localWipePendingKey = 'account_deletion_pending_local_wipe';

  static Future<ApiResult<bool>> finishAfterIdentityDeleted({
    required AuthService auth,
    required LocalStorage storage,
    required SecureStorage secureStorage,
    required String identityCleanupKey,
  }) async {
    AccountDeletionPendingState.markFinalizing();
    try {
      await storage.setBool(localWipePendingKey, true).requireDurable();
      await storage.remove(identityCleanupKey).requireDurable();
      await storage.remove(serverDeletePendingKey).requireDurable();
    } catch (_) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }

    final defense = _localWipeOwnerDefense(auth: auth, storage: storage);
    if (defense != null) return defense;

    final wipeResult = await UserLocalDataWipe.run(
      storage,
      secureStorage: secureStorage,
    );
    if (!wipeResult.isComplete) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }

    try {
      await storage.setBool(anonymousBootstrapKey, true).requireDurable();
      await storage.remove(localWipePendingKey).requireDurable();
      await storage.remove(UserLocalDataIsolation.ownerKey).requireDurable();
    } catch (_) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    AccountDeletionPendingState.markFinalizing();
    return completeAnonymousBootstrap(
      auth: auth,
      storage: storage,
      identityCleanupKey: identityCleanupKey,
    );
  }

  /// Never wipe an unrelated active owner's local state.
  static ApiResult<bool>? _localWipeOwnerDefense({
    required AuthService auth,
    required LocalStorage storage,
  }) {
    final target = AccountDeletionTarget.readTargetUid(storage);
    if (target == null) {
      AccountDeletionPendingState.markIntegrityRecovery();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    final live = auth.currentUserId?.trim();
    if (live != null && live.isNotEmpty && live != target) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    final owner =
        storage.getString(UserLocalDataIsolation.ownerKey)?.trim();
    if (owner != null && owner.isNotEmpty && owner != target) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    return null;
  }

  /// Creates or reuses ONLY the recorded replacement anonymous identity.
  static Future<ApiResult<bool>> completeAnonymousBootstrap({
    required AuthService auth,
    required LocalStorage storage,
    required String identityCleanupKey,
  }) async {
    if (!await storage.setBool(anonymousBootstrapKey, true)) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    AccountDeletionPendingState.markFinalizing();

    final recorded = AccountDeletionTarget.readBootstrapUid(storage);
    if (recorded != null) {
      return _resumeRecordedBootstrap(
        auth: auth,
        storage: storage,
        identityCleanupKey: identityCleanupKey,
        recorded: recorded,
      );
    }

    // No provenance yet — refuse any PRE-EXISTING identity (including anon).
    if (auth.hasCurrentIdentity) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }

    final session = await auth.ensureAnonymousSession();
    final created = auth.currentUserId?.trim();
    if (created == null ||
        created.isEmpty ||
        !auth.hasCurrentIdentity ||
        !auth.isCurrentUserAnonymous) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(
        session.errorOrNull ??
            NetworkException.unauthorized(AuthCopy.failed),
      );
    }
    // Record provenance even when session packaging failed after the
    // Firebase anonymous user already exists — retry must reuse THIS uid.
    if (!await AccountDeletionTarget.persistBootstrap(storage, created)) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    if (session.isFailure) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(
        session.errorOrNull ??
            NetworkException.unauthorized(AuthCopy.failed),
      );
    }
    return _clearAllMarkers(
      storage: storage,
      identityCleanupKey: identityCleanupKey,
    );
  }

  static Future<ApiResult<bool>> _resumeRecordedBootstrap({
    required AuthService auth,
    required LocalStorage storage,
    required String identityCleanupKey,
    required String recorded,
  }) async {
    final session = await auth.ensureAnonymousSession();
    if (session.isFailure) {
      return ApiFailure(
        session.errorOrNull ??
            NetworkException.unauthorized(AuthCopy.failed),
      );
    }
    final live = auth.currentUserId?.trim();
    if (!auth.hasCurrentIdentity ||
        !auth.isCurrentUserAnonymous ||
        live != recorded) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    return _clearAllMarkers(
      storage: storage,
      identityCleanupKey: identityCleanupKey,
    );
  }

  static Future<ApiResult<bool>> _clearAllMarkers({
    required LocalStorage storage,
    required String identityCleanupKey,
  }) async {
    if (!await storage.remove(identityCleanupKey)) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    if (!await storage.remove(localWipePendingKey)) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    if (!await storage.remove(serverDeletePendingKey)) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    if (!await storage.remove(anonymousBootstrapKey)) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    if (!await AccountDeletionTarget.clearTarget(storage)) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    if (!await AccountDeletionTarget.clearBootstrap(storage)) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    if (AccountDeletionMarkers.isExactlyTrue(
          storage,
          serverDeletePendingKey,
        ) ||
        AccountDeletionMarkers.isExactlyTrue(storage, identityCleanupKey) ||
        AccountDeletionMarkers.isExactlyTrue(storage, localWipePendingKey) ||
        AccountDeletionMarkers.isExactlyTrue(storage, anonymousBootstrapKey) ||
        AccountDeletionTarget.hasValidTarget(storage) ||
        AccountDeletionTarget.readBootstrapUid(storage) != null) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    AccountDeletionPendingState.markClear();
    UserLocalDataIsolation.accountSwitchEpoch.value++;
    return const ApiSuccess(true);
  }
}
