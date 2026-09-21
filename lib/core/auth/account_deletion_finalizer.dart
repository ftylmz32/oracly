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

  /// Durable creation-intent provenance: armed BEFORE Firebase is ever
  /// asked to create a replacement anonymous identity, so that if the
  /// SUBSEQUENT [AccountDeletionTarget.persistBootstrap] write fails after
  /// Firebase already created one, a retry can recognize the resulting
  /// live anonymous identity as belonging to THIS bootstrap attempt rather
  /// than refusing it as an unrelated pre-existing identity. Cleared as
  /// soon as [AccountDeletionTarget.persistBootstrap] durably succeeds —
  /// bootstrapUid itself is the provenance from then on.
  static const bootstrapCreationArmedKey =
      'account_deletion_bootstrap_creation_armed';

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

    final creationArmed = AccountDeletionMarkers.read(
      storage,
      bootstrapCreationArmedKey,
    );
    if (creationArmed == MarkerRead.corrupt) {
      AccountDeletionPendingState.markIntegrityRecovery();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    if (creationArmed != MarkerRead.isTrue) {
      // No provenance yet, and no creation attempt was ever armed — a
      // current identity here belongs to some unrelated flow, never to
      // this deletion's replacement bootstrap. Refuse it.
      if (auth.hasCurrentIdentity) {
        AccountDeletionPendingState.markFinalizing();
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
      if (!await storage.setBool(bootstrapCreationArmedKey, true)) {
        AccountDeletionPendingState.markFinalizing();
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
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
    // Armed flag is retired only inside _clearAllMarkers — removing it
    // here would open a CLEAR path that still leaves armed=true if later
    // steps fail after markClear conditions are wrongly met.
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

  /// Retirement order is the entire point of this function: [
  /// anonymousBootstrapKey] — the LAST remaining durable phase marker by
  /// the time this runs — must stay `true` until target/bootstrap
  /// provenance cleanup has ALREADY durably succeeded. Removing it first
  /// (the previous, buggy order) opened a restart window where a crash
  /// between that removal and the provenance cleanup below left every
  /// boolean phase marker absent while stale `targetUid`/`bootstrapUid`
  /// provenance was still on disk — indistinguishable from a genuinely
  /// clear device unless a caller specifically re-checks provenance too.
  /// Only the LAST successful write here (anonymousBootstrapKey's own
  /// removal) may retire the final gate authority.
  static Future<ApiResult<bool>> _clearAllMarkers({
    required LocalStorage storage,
    required String identityCleanupKey,
  }) async {
    // Already-absent-by-construction at this point in the normal flow —
    // attempted defensively so a historical/partial state converges too.
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

    // Provenance cleanup BEFORE the last durable gate marker is retired.
    if (!await AccountDeletionTarget.clearTarget(storage)) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    if (!await AccountDeletionTarget.clearBootstrap(storage)) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    // Creation-armed bookkeeping must not survive CLEAR — a stale true
    // would skip the "refuse pre-existing identity" defense on a later
    // deletion cycle.
    if (!await storage.remove(bootstrapCreationArmedKey)) {
      AccountDeletionPendingState.markFinalizing();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }

    // ONLY NOW — target, bootstrap uid, and armed provenance are already
    // durably gone — may the final gate authority itself be retired.
    if (!await storage.remove(anonymousBootstrapKey)) {
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
        AccountDeletionMarkers.isExactlyTrue(
          storage,
          bootstrapCreationArmedKey,
        ) ||
        AccountDeletionMarkers.read(storage, bootstrapCreationArmedKey) ==
            MarkerRead.corrupt ||
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
