/// Canonical account deletion: remote identity first, then local wipe.
library;

import '../data/datasources/local_storage.dart';
import '../network/api_result.dart';
import '../network/network_exception.dart';
import '../notifications/push_token_cleanup.dart';
import '../storage/secure_storage.dart';
import 'account_deletion_pending_state.dart';
import 'auth_copy.dart';
import 'auth_service.dart';
import 'models/auth_credentials.dart';
import 'user_local_data_isolation.dart';
import 'user_local_data_wipe.dart';

class AccountDeletionService {
  AccountDeletionService({
    required this._auth,
    required this._storage,
    required this._secureStorage,
    required this.deleteServerData,
  });

  final AuthService _auth;
  final LocalStorage _storage;
  final SecureStorage _secureStorage;
  final Future<bool> Function() deleteServerData;

  static const pendingIdentityCleanupKey =
      'account_deletion_pending_identity_cleanup';

  bool get hasPendingIdentityCleanup =>
      _storage.getBool(pendingIdentityCleanupKey) ?? false;

  /// Linked users require [reauth]. On reauth cancel/fail: zero destructive
  /// work. After server deletion succeeds, any unproven identity deletion
  /// enters pending cleanup (not only `requires-recent-login`).
  Future<ApiResult<bool>> deleteAccountAndWipeLocalData({
    AccountReauthCredentials? reauth,
  }) async {
    if (!_auth.hasCurrentIdentity) {
      return ApiFailure(
        NetworkException.unauthorized(AuthCopy.noCurrentUser),
      );
    }

    if (!_auth.isCurrentUserAnonymous) {
      if (reauth == null) {
        return ApiFailure(
          NetworkException.unauthorized(AuthCopy.requiresRecentLogin),
        );
      }
      final reauthResult = await _auth.reauthenticate(reauth);
      if (reauthResult.isFailure) {
        return ApiFailure(reauthResult.errorOrNull!);
      }
    }

    final serverAccepted = await deleteServerData();
    if (!serverAccepted) {
      return ApiFailure(
        NetworkException.unauthorized('Account data could not be deleted.'),
      );
    }
    await PushTokenCleanup.deleteLocalToken();

    final remote = await _auth.deleteAccount();
    if (remote.isFailure) {
      return _afterIdentityDeleteFailure(remote.errorOrNull!);
    }

    await _finishAfterIdentityDeleted();
    return const ApiSuccess(true);
  }

  /// [pendingIdentityCleanup] means server deletion was already accepted.
  /// Retry: optional reauth → prove identity gone → local wipe only.
  /// No second authenticated server deletion (token may already be cleared).
  Future<ApiResult<bool>> retryPendingIdentityCleanup({
    AccountReauthCredentials? reauth,
  }) async {
    if (!hasPendingIdentityCleanup) return const ApiSuccess(true);

    if (!_auth.isCurrentUserAnonymous && reauth != null) {
      final reauthResult = await _auth.reauthenticate(reauth);
      if (reauthResult.isFailure) {
        return ApiFailure(reauthResult.errorOrNull!);
      }
    }

    if (!_auth.hasCurrentIdentity) {
      await _finishAfterIdentityDeleted();
      return const ApiSuccess(true);
    }

    final stillPresent = await _auth.deleteAccount();
    if (stillPresent.isFailure) {
      final error = stillPresent.errorOrNull!;
      if (!_auth.hasCurrentIdentity) {
        await _finishAfterIdentityDeleted();
        return const ApiSuccess(true);
      }
      await _markPending();
      return ApiFailure(error);
    }

    await _finishAfterIdentityDeleted();
    return const ApiSuccess(true);
  }

  Future<ApiResult<bool>> _afterIdentityDeleteFailure(
    NetworkException error,
  ) async {
    // Identity already gone — finish wipe rather than looping forever.
    if (!_auth.hasCurrentIdentity) {
      await _finishAfterIdentityDeleted();
      return const ApiSuccess(true);
    }
    await _markPending();
    return ApiFailure(error);
  }

  Future<void> _markPending() async {
    await _storage.setBool(pendingIdentityCleanupKey, true);
    AccountDeletionPendingState.markBlocked();
  }

  Future<void> _finishAfterIdentityDeleted() async {
    await UserLocalDataWipe.run(_storage, secureStorage: _secureStorage);
    await _storage.remove(UserLocalDataIsolation.ownerKey);
    await _storage.remove(pendingIdentityCleanupKey);
    AccountDeletionPendingState.markClear();
    UserLocalDataIsolation.accountSwitchEpoch.value++;
    await _auth.ensureAnonymousSession();
  }
}
