/// Real AuthService implementation. Screens depend on AuthService only.
library;

import 'dart:async';

import '../../network/api_result.dart';
import '../../network/network_exception.dart';
import '../auth_copy.dart';
import '../auth_service.dart';
import '../models/auth_credentials.dart';
import '../models/auth_session.dart';
import '../session_manager.dart';
import '../token_manager.dart';
import '../user_local_data_isolation.dart';
import 'firebase_auth_errors.dart';
import 'firebase_auth_gateway.dart';
import 'firebase_auth_user.dart';
import 'firebase_session_mapper.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    required FirebaseAuthGateway gateway,
    TokenManager? tokens,
    SessionManager? sessions,
    UserLocalDataIsolation? isolation,
  })  : _gateway = gateway,
        _tokens = tokens,
        _sessions = sessions,
        _isolation = isolation {
    _sub = _gateway.authStateChanges().listen(_syncSession);
  }

  final FirebaseAuthGateway _gateway;
  final TokenManager? _tokens;
  final SessionManager? _sessions;
  final UserLocalDataIsolation? _isolation;
  StreamSubscription<FirebaseAuthUserSnapshot?>? _sub;

  @override
  bool get isConfigured => _gateway.isInitialized;

  void dispose() => _sub?.cancel();

  @override
  Future<ApiResult<AuthSession>> signInAnonymously() {
    return _sign(() => _gateway.signInAnonymously());
  }

  @override
  Future<ApiResult<AuthSession>> createGuestSession() => signInAnonymously();

  @override
  Future<ApiResult<AuthSession>> ensureAnonymousSession() {
    final user = _gateway.currentUser;
    if (user != null) return _sessionFromUser(user);
    return signInAnonymously();
  }

  @override
  Future<ApiResult<AuthSession>> signInWithEmail(EmailCredentials credentials) {
    return _sign(
      () => _gateway.signInWithEmail(
        email: credentials.email,
        password: credentials.password,
      ),
      provider: AuthProviderKind.email,
    );
  }

  @override
  Future<ApiResult<AuthSession>> signInWithGoogle(OAuthCredentials credentials) {
    return _sign(
      () => _gateway.signInWithGoogle(
        idToken: credentials.idToken,
        accessToken: credentials.accessToken,
      ),
      provider: AuthProviderKind.google,
    );
  }

  @override
  Future<ApiResult<AuthSession>> signInWithApple(OAuthCredentials credentials) {
    return _sign(
      () => _gateway.signInWithApple(idToken: credentials.idToken),
      provider: AuthProviderKind.apple,
    );
  }

  @override
  Future<ApiResult<AuthSession>> refreshSession() async {
    return _sessionFromUser(
      _gateway.currentUser,
      forceRefresh: true,
      provider: _sessions?.currentSession?.provider ?? AuthProviderKind.anonymous,
    );
  }

  @override
  Future<ApiResult<bool>> signOut() async {
    await _gateway.signOut();
    await _sessions?.clearSession();
    await _tokens?.clearTokens();
    return const ApiSuccess(true);
  }

  Future<ApiResult<AuthSession>> _sign(
    Future<FirebaseAuthUserSnapshot> Function() action, {
    AuthProviderKind provider = AuthProviderKind.anonymous,
  }) async {
    try {
      final user = await action();
      return _sessionFromUser(user, provider: provider);
    } on AuthGatewayException catch (e) {
      return ApiFailure(FirebaseAuthErrors.map(e));
    } catch (_) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
  }

  Future<ApiResult<AuthSession>> _sessionFromUser(
    FirebaseAuthUserSnapshot? user, {
    bool forceRefresh = false,
    AuthProviderKind provider = AuthProviderKind.anonymous,
  }) async {
    if (user == null) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    try {
      final token = await _gateway.currentIdToken(forceRefresh: forceRefresh);
      if (token == null || token.isEmpty || token.startsWith('mock_')) {
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
      final session = FirebaseSessionMapper.fromUser(
        user: user,
        idToken: token,
        provider: provider,
      );
      await _sessions?.setSession(session);
      await _isolation?.onSignedIn(user.uid);
      return ApiSuccess(session);
    } on AuthGatewayException catch (e) {
      return ApiFailure(FirebaseAuthErrors.map(e));
    }
  }

  Future<void> _syncSession(FirebaseAuthUserSnapshot? user) async {
    if (user == null) {
      await _sessions?.clearSession();
      await _tokens?.clearTokens();
      return;
    }
    await _sessionFromUser(user);
  }
}
