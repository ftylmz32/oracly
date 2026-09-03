/// Production/staging without Firebase — typed failure, never mock tokens.
library;

import '../network/api_result.dart';
import '../network/network_exception.dart';
import 'auth_copy.dart';
import 'auth_service.dart';
import 'models/auth_credentials.dart';
import 'models/auth_session.dart';
import 'session_manager.dart';
import 'token_manager.dart';

class UnconfiguredAuthService implements AuthService {
  UnconfiguredAuthService({TokenManager? tokens, SessionManager? sessions})
      : _tokens = tokens,
        _sessions = sessions;

  final TokenManager? _tokens;
  final SessionManager? _sessions;

  @override
  bool get isConfigured => false;

  @override
  Future<ApiResult<AuthSession>> signInAnonymously() async => _fail();

  @override
  Future<ApiResult<AuthSession>> signInWithGoogle(
    OAuthCredentials credentials,
  ) async =>
      _fail();

  @override
  Future<ApiResult<AuthSession>> signInWithApple(
    OAuthCredentials credentials,
  ) async =>
      _fail();

  @override
  Future<ApiResult<AuthSession>> signInWithEmail(
    EmailCredentials credentials,
  ) async =>
      _fail();

  @override
  Future<ApiResult<AuthSession>> createGuestSession() async => _fail();

  @override
  Future<ApiResult<AuthSession>> refreshSession() async => _fail();

  @override
  Future<ApiResult<AuthSession>> ensureAnonymousSession() async => _fail();

  @override
  Future<ApiResult<bool>> signOut() async {
    await _sessions?.clearSession();
    await _tokens?.clearTokens();
    return const ApiSuccess(true);
  }

  @override
  Future<ApiResult<bool>> deleteAccount() async => ApiFailure(
        NetworkException.unauthorized(AuthCopy.notConfigured),
      );

  ApiFailure<AuthSession> _fail() => ApiFailure(
        NetworkException.unauthorized(AuthCopy.notConfigured),
      );
}
