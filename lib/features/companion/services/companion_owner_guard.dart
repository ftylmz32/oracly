/// OR persistence owner — live auth identity, committed local owner, epoch.
library;

import 'package:flutter/foundation.dart';

import '../../../core/auth/account_deletion_pending_state.dart';
import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/data/datasources/local_storage.dart';

/// Who owned local OR data when a send intent started.
@immutable
final class CompanionOwnerSnapshot {
  const CompanionOwnerSnapshot({
    required this.authOwnerId,
    required this.localOwnerId,
    required this.epoch,
    required this.ownerBoundAllowed,
  });

  /// Identity could not be read; never writable.
  static const unknown = CompanionOwnerSnapshot(
    authOwnerId: '',
    localOwnerId: '',
    epoch: -1,
    ownerBoundAllowed: false,
  );

  /// `''` when nobody is signed in.
  final String authOwnerId;

  /// [UserLocalDataIsolation.ownerKey]; `''` before any owner was committed.
  final String localOwnerId;
  final int epoch;
  final bool ownerBoundAllowed;

  /// Auth and the committed local owner agree. During an account-switch wipe
  /// auth is already the next owner while the local owner is still the
  /// previous one, and that window is never writable. With no owner at all,
  /// data stays device-local exactly as `UserLocalDataIsolation` adopts it
  /// for the first owner.
  bool get isSettled =>
      ownerBoundAllowed && epoch >= 0 && authOwnerId == localOwnerId;

  @override
  bool operator ==(Object other) =>
      other is CompanionOwnerSnapshot &&
      other.authOwnerId == authOwnerId &&
      other.localOwnerId == localOwnerId &&
      other.epoch == epoch &&
      other.ownerBoundAllowed == ownerBoundAllowed;

  @override
  int get hashCode =>
      Object.hash(authOwnerId, localOwnerId, epoch, ownerBoundAllowed);
}

/// Captured when an OR send starts and re-checked before every conversation
/// write of that send. A reply that returns after the owner moved on — even
/// mid-wipe, before the switch epoch bumps — is never written.
class CompanionOwnerGuard {
  CompanionOwnerGuard({
    required this._liveOwnerId,
    required this._localOwnerId,
  });

  /// Local owner from [UserLocalDataIsolation.ownerKey] — the one authority.
  factory CompanionOwnerGuard.fromStorage(
    LocalStorage storage, {
    required String? Function() liveOwnerId,
  }) => CompanionOwnerGuard(
    liveOwnerId: liveOwnerId,
    localOwnerId: () => storage.getString(UserLocalDataIsolation.ownerKey),
  );

  final String? Function() _liveOwnerId;
  final String? Function() _localOwnerId;

  CompanionOwnerSnapshot capture() {
    try {
      return CompanionOwnerSnapshot(
        authOwnerId: _liveOwnerId()?.trim() ?? '',
        localOwnerId: _localOwnerId()?.trim() ?? '',
        epoch: UserLocalDataIsolation.accountSwitchEpoch.value,
        ownerBoundAllowed:
            AccountDeletionPendingState.allowsOwnerBoundExperience,
      );
    } catch (_) {
      return CompanionOwnerSnapshot.unknown;
    }
  }

  bool stillValid(CompanionOwnerSnapshot snapshot) =>
      snapshot.isSettled && capture() == snapshot;
}
