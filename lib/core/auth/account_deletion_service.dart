/// Canonical account deletion: remote identity first, then local wipe.
library;

import '../data/datasources/local_storage.dart';
import '../network/api_result.dart';
import '../storage/secure_storage.dart';
import 'auth_service.dart';
import 'user_local_data_isolation.dart';
import 'user_local_data_wipe.dart';

class AccountDeletionService {
  AccountDeletionService({
    required this._auth,
    required this._storage,
    required this._secureStorage,
  });

  final AuthService _auth;
  final LocalStorage _storage;
  final SecureStorage _secureStorage;

  /// Deletes the Firebase (or mock) account, then clears user-bound local data.
  /// On remote failure: does not wipe, does not claim success, does not logout.
  Future<ApiResult<bool>> deleteAccountAndWipeLocalData() async {
    final remote = await _auth.deleteAccount();
    if (remote.isFailure) {
      return ApiFailure(remote.errorOrNull!);
    }

    await UserLocalDataWipe.run(
      _storage,
      secureStorage: _secureStorage,
    );
    await _storage.remove(UserLocalDataIsolation.ownerKey);
    UserLocalDataIsolation.accountSwitchEpoch.value++;

    // Fresh anonymous session so the app stays in a valid startup state.
    await _auth.ensureAnonymousSession();
    return const ApiSuccess(true);
  }
}
