/// Local cache for Google Play / App Store reviewer access — never proves
/// entitlement by itself; the code is re-checked against the backend on
/// every reconcile so a server-side disable takes effect without a new
/// client build. Deliberately separate from [PremiumRepository]: never
/// touches purchase credentials, the active-plan flag, or the
/// authoritative-verification flag real paid entitlement relies on.
library;

import '../../storage/premium_credential_keys.dart';
import '../../storage/secure_storage.dart';
import '../datasources/local_storage.dart';

class ReviewAccessRepository {
  ReviewAccessRepository(this._storage, {required SecureStorage secureStorage})
      : _secure = secureStorage;

  final LocalStorage _storage;
  final SecureStorage _secure;

  /// Non-secret local flag — never treated as authoritative on its own.
  static const grantedKey = 'or_review_access_granted';

  bool get isGrantedLocally => _storage.getBool(grantedKey) ?? false;

  Future<String?> readStoredCode() =>
      _secure.read(PremiumCredentialKeys.reviewAccessCode);

  /// Called only after a server response with `granted: true`. Writes the
  /// code first and verifies the secure-storage write actually round-trips
  /// before ever setting the local "granted" flag — a silent secure-storage
  /// write failure must never leave the flag true with no code behind it.
  /// Returns whether persistence genuinely succeeded.
  Future<bool> markGranted(String code) async {
    await _secure.write(PremiumCredentialKeys.reviewAccessCode, code);
    final verify = await _secure.read(PremiumCredentialKeys.reviewAccessCode);
    if (verify != code) return false;
    await _storage.setBool(grantedKey, true);
    return _storage.getBool(grantedKey) ?? false;
  }

  /// Called when the server no longer grants the stored code (disabled,
  /// wrong, or reconfigured) — self-healing revocation, no client update.
  Future<void> clear() async {
    await _storage.setBool(grantedKey, false);
    await _secure.delete(PremiumCredentialKeys.reviewAccessCode);
  }
}
