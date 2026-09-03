/// OR-1130 — Authentication service contract.
library;

import '../network/api_result.dart';
import 'models/auth_credentials.dart';
import 'models/auth_session.dart';

abstract class AuthService {
  /// False when production has no real identity provider configured.
  bool get isConfigured;

  Future<ApiResult<AuthSession>> signInAnonymously();
  Future<ApiResult<AuthSession>> signInWithGoogle(OAuthCredentials credentials);
  Future<ApiResult<AuthSession>> signInWithApple(OAuthCredentials credentials);
  Future<ApiResult<AuthSession>> signInWithEmail(EmailCredentials credentials);
  Future<ApiResult<AuthSession>> createGuestSession();
  Future<ApiResult<AuthSession>> refreshSession();

  /// Reuse the current Firebase user, or sign in anonymously when none exists.
  Future<ApiResult<AuthSession>> ensureAnonymousSession();

  Future<ApiResult<bool>> signOut();

  /// Deletes the identity provider account. Does not wipe local data —
  /// callers must run [AccountDeletionService] so wipe happens only after
  /// remote success. Never reports success for logout-only.
  Future<ApiResult<bool>> deleteAccount();
}
