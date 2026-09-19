/// Canonical account deletion: remote identity first, then local wipe.
library;

import '../data/datasources/local_storage.dart';
import '../network/api_result.dart';
import '../network/network_exception.dart';
import '../notifications/push_token_cleanup.dart';
import '../storage/secure_storage.dart';
import 'auth_copy.dart';
import 'auth_service.dart';
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

  /// Durable marker: server-owned data was already deleted, but the Firebase
  /// identity itself could not be (typically `requires-recent-login`). While
  /// set, the app must never behave as if this were a normal, healthy
  /// account — it must retry identity deletion (and only then the local
  /// wipe) at the next safe opportunity, rather than silently continuing to
  /// operate as the old identity whose server data no longer exists.
  static const _pendingIdentityCleanupKey =
      'account_deletion_pending_identity_cleanup';

  bool get hasPendingIdentityCleanup =>
      _storage.getBool(_pendingIdentityCleanupKey) ?? false;

  /// Deletes the Firebase (or mock) account, then clears user-bound local data.
  /// On remote failure: does not wipe, does not claim success, does not logout.
  Future<ApiResult<bool>> deleteAccountAndWipeLocalData() async {
    // Server-owned content must be accepted for deletion before the Firebase
    // identity (and therefore its authorization to retry) is destroyed.
    final serverAccepted = await deleteServerData();
    if (!serverAccepted) {
      return ApiFailure(
        NetworkException.unauthorized('Account data could not be deleted.'),
      );
    }
    // Server-side deletion is already authoritative for owner-wide
    // notification-token cleanup (every token/registration row scoped to
    // this owner is purged as part of deleteServerData()). This is an
    // additional, purely local, best-effort step that never blocks or
    // weakens the server-first ordering below.
    await PushTokenCleanup.deleteLocalToken();

    final remote = await _auth.deleteAccount();
    if (remote.isFailure) {
      final error = remote.errorOrNull!;
      if (_requiresRecentLogin(error)) {
        // Server data is already gone but the identity survives — never
        // pretend this is a normal, healthy account from here on. Persist a
        // durable marker so a future reauth + retry can finish the identity
        // deletion and local wipe; server deletion is idempotent, so
        // calling it again on retry is safe even though it already ran.
        await _storage.setBool(_pendingIdentityCleanupKey, true);
      }
      return ApiFailure(error);
    }

    await _finishAfterIdentityDeleted();
    return const ApiSuccess(true);
  }

  /// Call once reauthentication has succeeded and the Firebase identity has
  /// actually been deleted (or on next startup if it turns out the identity
  /// was already gone by some other path) to complete the interrupted
  /// deletion: re-runs server deletion (idempotent — safe even though it
  /// already succeeded the first time) then finishes the local wipe.
  Future<ApiResult<bool>> retryPendingIdentityCleanup() async {
    if (!hasPendingIdentityCleanup) return const ApiSuccess(true);

    final stillPresent = await _auth.deleteAccount();
    if (stillPresent.isFailure) {
      // Still cannot delete the identity (e.g. reauth not actually done
      // yet) — stay in the pending state, never wipe, never claim success.
      return ApiFailure(stillPresent.errorOrNull!);
    }

    await deleteServerData();
    await _finishAfterIdentityDeleted();
    return const ApiSuccess(true);
  }

  Future<void> _finishAfterIdentityDeleted() async {
    await UserLocalDataWipe.run(_storage, secureStorage: _secureStorage);
    await _storage.remove(UserLocalDataIsolation.ownerKey);
    await _storage.remove(_pendingIdentityCleanupKey);
    UserLocalDataIsolation.accountSwitchEpoch.value++;

    // Fresh anonymous session so the app stays in a valid startup state.
    await _auth.ensureAnonymousSession();
  }

  bool _requiresRecentLogin(NetworkException error) =>
      error.message == AuthCopy.requiresRecentLogin;
}
