/// Canonical account deletion: remote identity first, then local wipe.
library;

import '../data/datasources/local_storage.dart';
import '../network/api_result.dart';
import '../network/network_exception.dart';
import '../notifications/push_token_cleanup.dart';
import '../storage/secure_storage.dart';
import 'account_deletion_finalizer.dart';
import 'account_deletion_markers.dart';
import 'account_deletion_pending_state.dart';
import 'auth_copy.dart';
import 'auth_service.dart';
import 'models/auth_credentials.dart';

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
  static const pendingAnonymousBootstrapKey =
      AccountDeletionFinalizer.anonymousBootstrapKey;

  /// A corrupt (wrong-type) marker counts as pending — never as "absent".
  /// See [AccountDeletionMarkers].
  bool get hasPendingIdentityCleanup =>
      AccountDeletionMarkers.isPendingOrCorrupt(
        _storage,
        pendingIdentityCleanupKey,
      );
  bool get hasPendingAnonymousBootstrap =>
      AccountDeletionMarkers.isPendingOrCorrupt(
        _storage,
        pendingAnonymousBootstrapKey,
      );
  bool get hasPendingFinalization =>
      hasPendingIdentityCleanup || hasPendingAnonymousBootstrap;

  Future<ApiResult<bool>> deleteAccountAndWipeLocalData({
    AccountReauthCredentials? reauth,
  }) async {
    if (!_auth.hasCurrentIdentity) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.noCurrentUser));
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
    return _finish();
  }

  Future<ApiResult<bool>> retryPendingIdentityCleanup({
    AccountReauthCredentials? reauth,
  }) async {
    if (hasPendingAnonymousBootstrap) {
      return AccountDeletionFinalizer.completeAnonymousBootstrap(
        auth: _auth,
        storage: _storage,
        identityCleanupKey: pendingIdentityCleanupKey,
      );
    }
    if (!hasPendingIdentityCleanup) return const ApiSuccess(true);
    if (!_auth.isCurrentUserAnonymous && reauth != null) {
      final reauthResult = await _auth.reauthenticate(reauth);
      if (reauthResult.isFailure) {
        return ApiFailure(reauthResult.errorOrNull!);
      }
    }
    if (!_auth.hasCurrentIdentity) return _finish();
    final stillPresent = await _auth.deleteAccount();
    if (stillPresent.isFailure) {
      final error = stillPresent.errorOrNull!;
      if (!_auth.hasCurrentIdentity) return _finish();
      await _markIdentityPending();
      return ApiFailure(error);
    }
    return _finish();
  }

  Future<ApiResult<bool>> _afterIdentityDeleteFailure(
    NetworkException error,
  ) async {
    if (!_auth.hasCurrentIdentity) return _finish();
    await _markIdentityPending();
    return ApiFailure(error);
  }

  Future<ApiResult<bool>> _finish() =>
      AccountDeletionFinalizer.finishAfterIdentityDeleted(
        auth: _auth,
        storage: _storage,
        secureStorage: _secureStorage,
        identityCleanupKey: pendingIdentityCleanupKey,
      );

  Future<void> _markIdentityPending() async {
    await _storage.setBool(pendingIdentityCleanupKey, true);
    await _storage.remove(pendingAnonymousBootstrapKey);
    AccountDeletionPendingState.markBlocked();
  }
}
