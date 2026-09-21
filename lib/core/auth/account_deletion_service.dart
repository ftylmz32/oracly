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
import 'account_deletion_target.dart';
import 'auth_copy.dart';
import 'auth_service.dart';
import 'models/auth_credentials.dart';
import 'user_local_data_isolation.dart';

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

  /// Receives the DURABLE deletion target uid as an anti-race assertion —
  /// see [AccountDeletionTarget]. The backend must independently re-verify
  /// this against the authenticated request's own identity and reject on
  /// mismatch; this parameter is never itself an authorization mechanism.
  final Future<bool> Function(String expectedTargetUid) deleteServerData;

  static const pendingServerDeleteKey =
      AccountDeletionFinalizer.serverDeletePendingKey;
  static const pendingIdentityCleanupKey =
      'account_deletion_pending_identity_cleanup';
  static const pendingLocalWipeKey =
      AccountDeletionFinalizer.localWipePendingKey;
  static const pendingAnonymousBootstrapKey =
      AccountDeletionFinalizer.anonymousBootstrapKey;
  static const targetUidKey = AccountDeletionTarget.targetUidKey;

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
          MarkerRead.corrupt ||
      AccountDeletionMarkers.read(
            _storage,
            AccountDeletionFinalizer.bootstrapCreationArmedKey,
          ) ==
          MarkerRead.corrupt ||
      AccountDeletionTarget.isTargetCorrupt(_storage) ||
      AccountDeletionTarget.isBootstrapCorrupt(_storage);

  /// Marker true but no valid target (and legacy migrate failed).
  bool get hasOrphanDeletionMarker =>
      hasPendingFinalization &&
      !AccountDeletionTarget.hasValidTarget(_storage) &&
      !AccountDeletionTarget.isTargetCorrupt(_storage);

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
      AccountDeletionPendingState.markIntegrityRecovery();
      return ApiFailure(
        NetworkException(
          message: 'deletion_state_corrupt',
          kind: NetworkErrorKind.unauthorized,
        ),
      );
    }
    if (hasPendingFinalization) {
      final bound = await _ensureTargetBound();
      if (bound == null) {
        AccountDeletionPendingState.markIntegrityRecovery();
        return ApiFailure(
          NetworkException(
            message: 'deletion_target_unbound',
            kind: NetworkErrorKind.unauthorized,
          ),
        );
      }
    }
    if (hasPendingLocalWipe) return _finish();
    if (hasPendingAnonymousBootstrap) {
      return AccountDeletionFinalizer.completeAnonymousBootstrap(
        auth: _auth,
        storage: _storage,
        identityCleanupKey: pendingIdentityCleanupKey,
      );
    }
    if (hasPendingIdentityCleanup) {
      return _retryIdentityCleanup(reauth: reauth);
    }
    if (hasPendingServerDelete) {
      return _retryServerDelete(reauth: reauth);
    }
    return const ApiSuccess(true);
  }

  Future<ApiResult<bool>> _retryIdentityCleanup({
    AccountReauthCredentials? reauth,
  }) async {
    if (!await _retireServerDeletePendingIfPresent()) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    if (!_auth.hasCurrentIdentity) return _finish();
    if (!_guardCurrentIsTarget()) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    if (!_auth.isCurrentUserAnonymous && reauth != null) {
      final reauthResult = await _auth.reauthenticate(reauth);
      if (reauthResult.isFailure) {
        return ApiFailure(reauthResult.errorOrNull!);
      }
      if (!_guardCurrentIsTarget()) {
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
    }
    final stillPresent = await _auth.deleteAccount();
    if (stillPresent.isFailure) {
      final error = stillPresent.errorOrNull!;
      if (!_auth.hasCurrentIdentity) return _finish();
      await _markIdentityPending();
      return ApiFailure(error);
    }
    return _finish();
  }

  Future<ApiResult<bool>> _retryServerDelete({
    AccountReauthCredentials? reauth,
  }) async {
    if (!_auth.hasCurrentIdentity) {
      AccountDeletionPendingState.markBlocked();
      return ApiFailure(
        NetworkException.unauthorized(AuthCopy.noCurrentUser),
      );
    }
    if (!_guardCurrentIsTarget()) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    if (!_auth.isCurrentUserAnonymous && reauth != null) {
      final reauthResult = await _auth.reauthenticate(reauth);
      if (reauthResult.isFailure) {
        return ApiFailure(reauthResult.errorOrNull!);
      }
      if (!_guardCurrentIsTarget()) {
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
    }
    return _runFromServerDeletePhase(alreadyArmed: true);
  }

  Future<ApiResult<bool>> _runFromServerDeletePhase({
    bool alreadyArmed = false,
  }) async {
    if (!alreadyArmed) {
      final uid = _auth.currentUserId?.trim();
      if (uid == null || uid.isEmpty) {
        return ApiFailure(
          NetworkException.unauthorized(AuthCopy.noCurrentUser),
        );
      }
      // Audit local owner binding BEFORE the first destructive call of
      // any kind (server delete, identity delete) and before the target
      // is even persisted. A present-but-DIFFERENT ownerKey means this
      // device's local data belongs to someone else — never advance the
      // target, never call the server, never touch the identity. A null
      // ownerKey is a legitimate first-sign-in/bootstrap state and is not
      // itself a mismatch.
      final owner = _storage.getString(UserLocalDataIsolation.ownerKey)?.trim();
      if (owner != null && owner.isNotEmpty && owner != uid) {
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
      if (!await AccountDeletionTarget.persistTarget(_storage, uid)) {
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
      if (!await _storage.setBool(pendingServerDeleteKey, true)) {
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
      AccountDeletionPendingState.markBlocked();
    } else if (!_guardCurrentIsTarget()) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }

    // The durable target uid is sent as an anti-race assertion the
    // backend independently re-verifies against the authenticated
    // request's own identity — see AccountDeletionService.deleteServerData.
    final expectedTargetUid = AccountDeletionTarget.readTargetUid(_storage);
    if (expectedTargetUid == null) {
      AccountDeletionPendingState.markIntegrityRecovery();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }

    final bool serverAccepted;
    try {
      serverAccepted = await deleteServerData(expectedTargetUid);
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
    if (!await _storage.remove(pendingServerDeleteKey)) {
      AccountDeletionPendingState.markBlocked();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }

    if (!_guardCurrentIsTarget()) {
      AccountDeletionPendingState.markBlocked();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }

    final remote = await _auth.deleteAccount();
    if (remote.isFailure) {
      return _afterIdentityDeleteFailure(remote.errorOrNull!);
    }
    return _finish();
  }

  /// Returns the bound target uid, migrating legacy markers when safe.
  Future<String?> _ensureTargetBound() async {
    final existing = AccountDeletionTarget.readTargetUid(_storage);
    if (existing != null) return existing;
    if (AccountDeletionTarget.isTargetCorrupt(_storage)) return null;
    final migrated = await AccountDeletionTarget.tryMigrateLegacyTarget(
      storage: _storage,
      auth: _auth,
    );
    if (!migrated) return null;
    return AccountDeletionTarget.readTargetUid(_storage);
  }

  bool _guardCurrentIsTarget() {
    if (AccountDeletionTarget.currentMatchesTarget(
      storage: _storage,
      auth: _auth,
    )) {
      return true;
    }
    AccountDeletionPendingState.markBlocked();
    return false;
  }

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
