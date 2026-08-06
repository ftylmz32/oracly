/// OR-1130 — Authentication service contract.
library;

import '../network/api_result.dart';
import 'models/auth_credentials.dart';
import 'models/auth_session.dart';

abstract class AuthService {
  Future<ApiResult<AuthSession>> signInAnonymously();
  Future<ApiResult<AuthSession>> signInWithGoogle(OAuthCredentials credentials);
  Future<ApiResult<AuthSession>> signInWithApple(OAuthCredentials credentials);
  Future<ApiResult<AuthSession>> signInWithEmail(EmailCredentials credentials);
  Future<ApiResult<AuthSession>> createGuestSession();
  Future<ApiResult<AuthSession>> refreshSession();
  Future<ApiResult<bool>> signOut();
}
