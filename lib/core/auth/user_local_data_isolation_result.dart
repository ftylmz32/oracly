/// Honest outcome of [UserLocalDataIsolation.onSignedIn] — a caller (the
/// auth/session layer) must never treat a new owner as isolated, and must
/// never publish an application session for them, unless this reports
/// success.
library;

import 'user_local_data_wipe_result.dart';

class UserLocalDataIsolationResult {
  const UserLocalDataIsolationResult._({
    required this.success,
    this.wipeResult,
  });

  /// No account switch was needed (same owner, or the very first sign-in
  /// on this device) — always safe to proceed.
  factory UserLocalDataIsolationResult.noSwitchNeeded() =>
      const UserLocalDataIsolationResult._(success: true);

  /// A switch was needed and the prior owner's account-scoped data was
  /// fully cleared before the new owner was committed.
  factory UserLocalDataIsolationResult.switched() =>
      const UserLocalDataIsolationResult._(success: true);

  /// A switch was needed but local cleanup did NOT fully complete — the
  /// prior owner's residue may still be on disk. The new owner's uid was
  /// deliberately NOT committed as the local owner; the caller must not
  /// publish an application session for them.
  factory UserLocalDataIsolationResult.wipeIncomplete(
    UserLocalDataWipeResult wipeResult,
  ) =>
      UserLocalDataIsolationResult._(success: false, wipeResult: wipeResult);

  /// Cleanup (or the very first sign-in on this device) succeeded, but the
  /// durable `ownerKey` write itself resolved `false` — a persistence
  /// failure, not an exception. [accountSwitchEpoch] must never bump, and
  /// the caller must not publish a session for the new uid: the prior
  /// owner's marker (or no marker at all, on a first sign-in) is left
  /// exactly as it was, which safely forces another attempt on retry.
  factory UserLocalDataIsolationResult.ownerCommitFailed() =>
      const UserLocalDataIsolationResult._(success: false);

  final bool success;

  /// Populated only when [success] is false — the exact wipe failure this
  /// isolation attempt hit.
  final UserLocalDataWipeResult? wipeResult;

  @override
  String toString() =>
      'UserLocalDataIsolationResult(success: $success, wipeResult: '
      '$wipeResult)';
}
