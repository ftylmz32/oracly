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
  static const pendingLocalWipeKey =
      AccountDeletionFinalizer.localWipePendingKey;
  static const pendingAnonymousBootstrapKey =
      AccountDeletionFinalizer.anonymousBootstrapKey;

  /// EXACT persisted `true` only — never a corrupt (wrong-type) value. A
  /// corrupt marker is unknown state, not evidence a deletion was ever
  /// requested or accepted, and must never authorize destructive work
  /// (server delete, identity delete, local wipe, anonymous-identity
  /// creation). See [AccountDeletionMarkers.isExactlyTrue].
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
      hasPendingIdentityCleanup ||
      hasPendingLocalWipe ||
      hasPendingAnonymousBootstrap;

  /// True when either marker is present but of the wrong type — unknown
  /// state that routing must fail closed on, but that must never by itself
  /// authorize any destructive account action. Routing-safety code should
  /// prefer [AccountDeletionPendingState] (which already fails closed to
  /// `integrityRecovery`); this getter exists so destructive-authority code
  /// (e.g. [retryPendingIdentityCleanup]) can refuse in depth even if
  /// invoked directly, bypassing the gate.
  bool get hasCorruptDeletionMarker =>
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
    final serverAccepted = await deleteServerData();
    if (!serverAccepted) {
      return ApiFailure(
        NetworkException.unauthorized('Account data could not be deleted.'),
      );
    }
    await PushTokenCleanup.deleteLocalToken();
    // Durable finalization authority must exist BEFORE the Firebase
    // identity can disappear. Arm and POSITIVELY VERIFY the
    // identity-cleanup marker first: if identity deletion then succeeds
    // and the app crashes (or a later marker write itself fails) before
    // finishAfterIdentityDeleted's own localWipePendingKey write lands,
    // this marker is what proves a restart is NOT "clear" — it means the
    // server already accepted deletion and local state must never be
    // treated as an ordinary signed-in account again. If this write
    // itself cannot be proven durable, the identity must not be deleted
    // at all — fail honestly with the identity still fully intact.
    if (!await _storage.setBool(pendingIdentityCleanupKey, true)) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    final remote = await _auth.deleteAccount();
    if (remote.isFailure) {
      return _afterIdentityDeleteFailure(remote.errorOrNull!);
    }
    return _finish();
  }

  Future<ApiResult<bool>> retryPendingIdentityCleanup({
    AccountReauthCredentials? reauth,
  }) async {
    // Defense in depth: a corrupt marker must never authorize destructive
    // work even if this is called directly, bypassing the startup gate
    // (which already refuses to invoke this for a corrupt marker).
    if (hasCorruptDeletionMarker) {
      return ApiFailure(
        NetworkException(
          message: 'deletion_state_corrupt',
          kind: NetworkErrorKind.unauthorized,
        ),
      );
    }
    if (hasPendingLocalWipe) {
      // Identity is already gone — retry ONLY the local wipe, never a
      // second destructive deleteAccount call on an already-deleted
      // identity.
      return _finish();
    }
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
    // Reinforce the identity-cleanup marker with an authoritative bool
    // result — a `false` here is a durable-write failure, not success.
    // (On the happy path the marker was already armed before deleteAccount;
    // this path covers failed deleteAccount while the identity still exists.)
    if (!await _storage.setBool(pendingIdentityCleanupKey, true)) {
      AccountDeletionPendingState.markBlocked();
      return;
    }
    // Best-effort retire of a stale anonymous-bootstrap marker. A false
    // remove must not clear the blocked phase: identityCleanup remaining
    // true is what keeps the gate fail-closed.
    if (!await _storage.remove(pendingAnonymousBootstrapKey)) {
      // Leave anonymousBootstrap as-is if still present; blocked phase
      // below is the honest signal.
    }
    AccountDeletionPendingState.markBlocked();
  }
}