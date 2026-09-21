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
      AccountDeletionFinalizer.serverDeletePendingKey;

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
    // identityCleanup means server acceptance was already proven. Prefer it
    // over a leftover serverDeletePending — but retire that leftover BEFORE
    // any Firebase identity work so it cannot attack a later anonymous owner.
    if (hasPendingIdentityCleanup) {
      if (!await _retireServerDeletePendingIfPresent()) {
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
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
      // Absence of Firebase identity is NOT proof the server accepted.
      // Never promote to identityCleanup without a real server accept.
      if (!_auth.hasCurrentIdentity) {
        AccountDeletionPendingState.markBlocked();
        return ApiFailure(
          NetworkException.unauthorized(AuthCopy.noCurrentUser),
        );
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
      if (!await _storage.setBool(pendingServerDeleteKey, true)) {
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
      AccountDeletionPendingState.markBlocked();
    }

    final bool serverAccepted;
    try {
      serverAccepted = await deleteServerData();
    } catch (_) {
      AccountDeletionPendingState.markBlocked();
      return ApiFailure(
        NetworkException.unauthorized('Account data could not be deleted.'),
      );
    }
    if (!serverAccepted) {
      AccountDeletionPendingState.markBlocked();
      return ApiFailure(
        NetworkException.unauthorized('Account data could not be deleted.'),
      );
    }

    await PushTokenCleanup.deleteLocalToken();

    if (!await _storage.setBool(pendingIdentityCleanupKey, true)) {
      AccountDeletionPendingState.markBlocked();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    // identityCleanup is durable — serverDeletePending is now obsolete and
    // MUST be retired before Firebase identity deletion may begin.
    if (!await _storage.remove(pendingServerDeleteKey)) {
      AccountDeletionPendingState.markBlocked();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }

    final remote = await _auth.deleteAccount();
    if (remote.isFailure) {
      return _afterIdentityDeleteFailure(remote.errorOrNull!);
    }
    return _finish();
  }

  /// Retires a leftover [pendingServerDeleteKey] after identityCleanup is
  /// already the authoritative phase. Returns false if the marker is still
  /// exactly true after the attempt (fail-closed — no identity work yet).
  Future<bool> _retireServerDeletePendingIfPresent() async {
    if (!hasPendingServerDelete) return true;
    if (!await _storage.remove(pendingServerDeleteKey)) {
      AccountDeletionPendingState.markBlocked();
      return false;
    }
    if (hasPendingServerDelete) {
      AccountDeletionPendingState.markBlocked();
      return false;
    }
    return true;
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
