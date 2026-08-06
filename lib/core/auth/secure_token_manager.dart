/// OR-1130 — Secure token storage implementation.
library;

import '../storage/secure_storage.dart';
import 'token_manager.dart';

class SecureTokenManager implements TokenManager {
  SecureTokenManager(this._storage);

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _expiresKey = 'auth_token_expires_at';

  final SecureStorage _storage;

  @override
  Future<String?> getAccessToken() => _storage.read(_accessKey);

  @override
  Future<String?> getRefreshToken() => _storage.read(_refreshKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    await _storage.write(_accessKey, accessToken);
    await _storage.write(_refreshKey, refreshToken);
    if (expiresAt != null) {
      await _storage.write(_expiresKey, expiresAt.toIso8601String());
    }
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(_accessKey);
    await _storage.delete(_refreshKey);
    await _storage.delete(_expiresKey);
  }

  @override
  Future<bool> hasValidAccessToken() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    final expiresRaw = await _storage.read(_expiresKey);
    if (expiresRaw == null) return true;
    return DateTime.now().isBefore(DateTime.parse(expiresRaw));
  }
}
