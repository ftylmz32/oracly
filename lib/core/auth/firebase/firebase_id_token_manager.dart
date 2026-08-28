/// TokenManager backed by Firebase ID tokens. Does not persist passwords.
library;

import '../token_manager.dart';
import 'firebase_auth_gateway.dart';

class FirebaseIdTokenManager implements TokenManager {
  FirebaseIdTokenManager(this._gateway, {TokenManager? fallback})
      : _fallback = fallback;

  final FirebaseAuthGateway _gateway;
  final TokenManager? _fallback;

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) {
    return _gateway.currentIdToken(forceRefresh: forceRefresh);
  }

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    // Firebase SDK owns the session. Do not store ID tokens locally.
  }

  @override
  Future<void> clearTokens() async {
    await _fallback?.clearTokens();
  }

  @override
  Future<bool> hasValidAccessToken() async {
    if (_gateway.currentUser == null) return false;
    final token = await getAccessToken();
    return token != null && token.isNotEmpty && !token.startsWith('mock_');
  }
}
