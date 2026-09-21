/// Ensures local prefs belong to the active auth user — wipes on account switch.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/datasources/local_storage.dart';
import '../storage/secure_storage.dart';
import 'user_local_data_isolation_result.dart';
import 'user_local_data_wipe.dart';

class UserLocalDataIsolation {
  UserLocalDataIsolation(
    this._storage, {
    required this.secureStorage,
  });

  static const ownerKey = 'or_local_data_owner_uid';

  /// Bumps ONLY after a switch's wipe has been proven complete.
  static final ValueNotifier<int> accountSwitchEpoch = ValueNotifier(0);

  final LocalStorage _storage;
  final SecureStorage secureStorage;

  /// Serializes every transition attempt through one queue, and lets
  /// concurrent callers for the SAME target uid share one in-flight
  /// result, instead of each independently reading `previous` and each
  /// starting its OWN [UserLocalDataWipe.run]. Without this, an explicit
  /// sign-in call and the auth-state-change listener reacting to the same
  /// underlying event could both observe `previous == A` and both start a
  /// wipe for A -> B; whichever finished first could commit owner B and
  /// let the app resume normal owner-bound work while the SECOND, now
  /// stale A -> B wipe was still running underneath it — removing data
  /// already created/warmed for B. Serializing different-target
  /// transitions also means a later switch always re-reads [ownerKey]
  /// only after every earlier transition has fully settled.
  Future<UserLocalDataIsolationResult>? _inFlight;
  String? _inFlightUid;
  Future<void> _queue = Future.value();

  /// Fails closed: [ownerKey] is committed to [userId] only when no
  /// switch was needed, or when a needed switch's wipe fully succeeded.
  /// On an incomplete wipe, the PRIOR owner's marker is left in place —
  /// it must remain sufficient to force another cleanup attempt before any
  /// distinct owner is treated as isolated on this device — and the
  /// caller (the auth/session layer) must not publish an application
  /// session for [userId] off the back of this result.
  Future<UserLocalDataIsolationResult> onSignedIn(String userId) {
    final uid = userId.trim();
    if (uid.isEmpty) {
      return Future.value(UserLocalDataIsolationResult.noSwitchNeeded());
    }

    // Same-target single-flight: a second concurrent caller for the SAME
    // uid shares this exact in-flight transition rather than starting an
    // independent, possibly-overlapping second one.
    final inFlight = _inFlight;
    if (inFlight != null && _inFlightUid == uid) {
      return inFlight;
    }

    // A different target (or nothing currently in flight): serialize
    // through the queue — this transition only actually starts once any
    // earlier one has fully settled, and reads ownerKey fresh at that
    // point, never a value some other in-flight transition might still be
    // in the middle of changing.
    final result = _queue.then((_) => _transition(uid));
    _inFlight = result;
    _inFlightUid = uid;
    // Chain onto the queue regardless of whether this transition threw —
    // a failure must never poison later, independent retries — but keep
    // the ORIGINAL error visible to whoever is awaiting `result` itself.
    _queue = result.then((_) {}, onError: (_) {});
    result.whenComplete(() {
      if (identical(_inFlight, result)) {
        _inFlight = null;
        _inFlightUid = null;
      }
    });
    return result;
  }

  Future<UserLocalDataIsolationResult> _transition(String uid) async {
    final previous = _storage.getString(ownerKey);
    if (previous == uid) {
      return UserLocalDataIsolationResult.noSwitchNeeded();
    }
    if (previous == null) {
      if (!await _storage.setString(ownerKey, uid)) {
        return UserLocalDataIsolationResult.ownerCommitFailed();
      }
      return UserLocalDataIsolationResult.noSwitchNeeded();
    }
    final wipeResult = await UserLocalDataWipe.run(
      _storage,
      secureStorage: secureStorage,
    );
    if (!wipeResult.isComplete) {
      return UserLocalDataIsolationResult.wipeIncomplete(wipeResult);
    }
    // ownerKey must be PROVEN durably committed to the new uid before the
    // epoch bumps — a caller reacting to accountSwitchEpoch must never
    // observe it before the new owner is actually safe to read/write as
    // current. On a false (non-throwing) write failure, the prior owner's
    // marker is left exactly as it was; that stale marker safely forces
    // another full attempt on retry rather than silently leaving the
    // device with no recorded owner at all.
    if (!await _storage.setString(ownerKey, uid)) {
      return UserLocalDataIsolationResult.ownerCommitFailed();
    }
    accountSwitchEpoch.value++;
    return UserLocalDataIsolationResult.switched();
  }

  String? get localOwnerId => _storage.getString(ownerKey);
}
