/// Ensures local prefs belong to the active auth user — wipes on account switch.
library;

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

  /// Fails closed: [ownerKey] is committed to [userId] only when no
  /// switch was needed, or when a needed switch's wipe fully succeeded.
  /// On an incomplete wipe, the PRIOR owner's marker is left in place —
  /// it must remain sufficient to force another cleanup attempt before any
  /// distinct owner is treated as isolated on this device — and the
  /// caller (the auth/session layer) must not publish an application
  /// session for [userId] off the back of this result.
  Future<UserLocalDataIsolationResult> onSignedIn(String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) return UserLocalDataIsolationResult.noSwitchNeeded();
    final previous = _storage.getString(ownerKey);
    if (previous != null && previous != uid) {
      final wipeResult = await UserLocalDataWipe.run(
        _storage,
        secureStorage: secureStorage,
      );
      if (!wipeResult.isComplete) {
        return UserLocalDataIsolationResult.wipeIncomplete(wipeResult);
      }
      accountSwitchEpoch.value++;
      await _storage.setString(ownerKey, uid);
      return UserLocalDataIsolationResult.switched();
    }
    await _storage.setString(ownerKey, uid);
    return UserLocalDataIsolationResult.noSwitchNeeded();
  }

  String? get localOwnerId => _storage.getString(ownerKey);
}
