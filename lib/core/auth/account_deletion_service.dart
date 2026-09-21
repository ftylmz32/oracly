/// Canonical account deletion: remote data → identity → local wipe.
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

  /// Durable evidence that server-side account deletion was REQUESTED and
  /// must be (re)attempted before any Firebase identity work. Armed BEFORE
  /// [deleteServerData] so a crash or false-return write never leaves the
  /// app with zero deletion authority after a server accept.
  static const pendingServerDeleteKey =
      'account_deletion_pending_server_delete';

  static const pendingIdentityCleanupKey =
      'account_deletion_pending_identity_cleanup';
  static const pendingLocalWipeKey =
      AccountDeletionFinalizer.localWipePendingKey;
  static const pendingAnonymousBootstrapKey =
      AccountDeletionFinalizer.anonymousBootstrapKey;

  /// EXACT persisted `true` only — never a corrupt (wrong-type) value.
  bool get hasPendingServerDelete => AccountDeletionMarkers.isExactlyTrue(
        _storage,
        pendingServerDeleteKey,
      );
  bool get hasPendingIdentityCleanup => AccountDeletionMarkers.isExactlyTrue(
        _storage,
        pendingIdentityCleanupKey,
      );
  bool get hasPendingLocalWipe => AccountDeletionMarkers.isExactlyTrue(
        _storage,
        pendingLocalWipeKey,
      );
  bool get hasPendingAnonymousBootstrap =>
      AccountDeletionMarkers.isExactlyTrue(
        _storage,
        pendingAnonymousBootstrapKey,
      );
  bool get hasPendingFinalization =>
      hasPendingServerDelete ||
      hasPendingIdentityCleanup ||
      hasPendingLocalWipe ||
      hasPendingAnonymousBootstrap;

  bool get hasCorruptDeletionMarker =>
      AccountDeletionMarkers.read(_storage, pendingServerDeleteKey) ==
          MarkerRead.corrupt ||
      AccountDeletionMarkers.read(_storage, pendingIdentityCleanupKey) ==
          MarkerRead.corrupt ||
      AccountDeletionMarkers.read(_storage, pendingLocalWipeKey) ==
          MarkerRead.corrupt ||
      AccountDeletionMarkers.read(_storage, pendingAnonymousBootstrapKey) ==
          MarkerRead.corrupt;

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
    return _runFromServerDeletePhase();
  }

  Future<ApiResult<bool>> retryPendingIdentityCleanup({
    AccountReauthCredentials? reauth,
  }) async {
    if (hasCorruptDeletionMarker) {
      return ApiFailure(
        NetworkException(
          message: 'deletion_state_corrupt',
          kind: NetworkErrorKind.unauthorized,
        ),
      );
    }
    if (hasPendingLocalWipe) return _finish();
    if (hasPendingAnonymousBootstrap) {
      return AccountDeletionFinalizer.completeAnonymousBootstrap(
        auth: _auth,
        storage: _storage,
        identityCleanupKey: pendingIdentityCleanupKey,
      );
    }
    // identityCleanup means the server phase already succeeded — prefer it
    // over a leftover serverDeletePending that failed to retire.
    if (hasPendingIdentityCleanup) {
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
    if (hasPendingServerDelete) {
      if (!_auth.hasCurrentIdentity) {
        return _promoteServerPhaseToIdentityCleanup();
      }
      if (!_auth.isCurrentUserAnonymous && reauth != null) {
        final reauthResult = await _auth.reauthenticate(reauth);
        if (reauthResult.isFailure) {
          return ApiFailure(reauthResult.errorOrNull!);
        }
      }
      return _runFromServerDeletePhase(alreadyArmed: true);
    }
    return const ApiSuccess(true);
  }

  /// Shared path for first-time delete and serverDeletePending retry.
  Future<ApiResult<bool>> _runFromServerDeletePhase({
    bool alreadyArmed = false,
  }) async {
    if (!alreadyArmed) {
      // Durable deletion authority BEFORE any destructive remote call.
      if (!await _storage.setBool(pendingServerDeleteKey, true)) {
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
      AccountDeletionPendingState.markBlocked();
    }

    final serverAccepted = await deleteServerData();
    if (!serverAccepted) {
      // Keep serverDeletePending — retry must call the SERVER again.
      // Never reinterpret this as permission to delete Firebase identity.
      AccountDeletionPendingState.markBlocked();
      return ApiFailure(
        NetworkException.unauthorized('Account data could not be deleted.'),
      );
    }

    await PushTokenCleanup.deleteLocalToken();

    // Promote to identityCleanup BEFORE retiring serverDeletePending —
    // never a marker-free gap after the server has accepted.
    if (!await _storage.setBool(pendingIdentityCleanupKey, true)) {
      // Server accepted, identityCleanup not durable — leave
      // serverDeletePending true so restart is never "clear".
      AccountDeletionPendingState.markBlocked();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    // Retire serverDeletePending only after identityCleanup is proven.
    if (!await _storage.remove(pendingServerDeleteKey)) {
      // identityCleanup is true — still fail-closed; retry will see
      // identityCleanup (and possibly leftover serverDeletePending).
      AccountDeletionPendingState.markBlocked();
    }

    final remote = await _auth.deleteAccount();
    if (remote.isFailure) {
      return _afterIdentityDeleteFailure(remote.errorOrNull!);
    }
    return _finish();
  }

  Future<ApiResult<bool>> _promoteServerPhaseToIdentityCleanup() async {
    if (!await _storage.setBool(pendingIdentityCleanupKey, true)) {
      AccountDeletionPendingState.markBlocked();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    await _storage.remove(pendingServerDeleteKey);
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
    if (!await _storage.setBool(pendingIdentityCleanupKey, true)) {
      AccountDeletionPendingState.markBlocked();
      return;
    }
    await _storage.remove(pendingAnonymousBootstrapKey);
    await _storage.remove(pendingServerDeleteKey);
    AccountDeletionPendingState.markBlocked();
  }
}
