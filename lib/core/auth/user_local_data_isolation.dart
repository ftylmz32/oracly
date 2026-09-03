/// Ensures local prefs belong to the active auth user — wipes on account switch.
library;

import 'package:flutter/foundation.dart';

import '../data/datasources/local_storage.dart';
import '../storage/secure_storage.dart';
import 'user_local_data_wipe.dart';

class UserLocalDataIsolation {
  UserLocalDataIsolation(
    this._storage, {
    required this.secureStorage,
  });

  static const ownerKey = 'or_local_data_owner_uid';

  /// Bumps when a different account wipes device-local data.
  static final ValueNotifier<int> accountSwitchEpoch = ValueNotifier(0);

  final LocalStorage _storage;
  final SecureStorage secureStorage;

  Future<void> onSignedIn(String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) return;
    final previous = _storage.getString(ownerKey);
    if (previous != null && previous != uid) {
      await UserLocalDataWipe.run(
        _storage,
        secureStorage: secureStorage,
      );
      accountSwitchEpoch.value++;
    }
    await _storage.setString(ownerKey, uid);
  }

  String? get localOwnerId => _storage.getString(ownerKey);
}
