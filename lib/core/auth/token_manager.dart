/// OR-1130 — Secure token persistence contract.
library;

abstract class TokenManager {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  });
  Future<void> clearTokens();
  Future<bool> hasValidAccessToken();
}
