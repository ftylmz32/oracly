/// TEST / LOCAL DEVELOPMENT ONLY. Forbidden in release/production.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../network/api_result.dart';
import '../network/network_exception.dart';
import 'auth_copy.dart';
import 'auth_service.dart';
import 'models/account_reauth_method.dart';
import 'models/auth_credentials.dart';
import 'models/auth_session.dart';
import 'session_manager.dart';
import 'token_manager.dart';
import 'user_local_data_isolation.dart';

class MockAuthService implements AuthService {
  MockAuthService({
    TokenManager? tokens,
    SessionManager? sessions,
    UserLocalDataIsolation? isolation,
  })  : _tokens = tokens,
        _sessions = sessions,
        _isolation = isolation {
    if (kReleaseMode) {
      throw StateError('MockAuthService is not allowed in release builds.');
    }
  }

  final TokenManager? _tokens;
  final SessionManager? _sessions;
  final UserLocalDataIsolation? _isolation;
  final _random = Random();

  @override
  bool get isConfigured => true;

  AuthSession _createSession(AuthProviderKind provider, {bool guest = false}) {
    final id = _random.nextInt(999999).toString().padLeft(6, '0');
    return AuthSession(
      userId: 'user_$id',
      provider: provider,
      accessToken: 'mock_access_$id',
      refreshToken: 'mock_refresh_$id',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      isGuest: guest,
    );
  }

  Future<ApiResult<AuthSession>> _finish(AuthSession session) async {
    // Same ordering + stale-session invariant as FirebaseAuthService:
    // isolation must be proven before the session is published, and a
    // DIFFERENT-uid session that fails isolation must not leave the OLD
    // uid's session sitting there either.
    final previousSessionUid = _sessions?.currentSession?.userId;
    final isDifferentUid =
        previousSessionUid != null && previousSessionUid != session.userId;
    final isolationResult = await _isolation?.onSignedIn(session.userId);
    if (isolationResult != null && !isolationResult.success) {
      if (isDifferentUid) await _sessions?.clearSession();
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    await _sessions?.setSession(session);
    return ApiSuccess(session);
  }

  @override
  Future<ApiResult<AuthSession>> signInAnonymously() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _finish(_createSession(AuthProviderKind.anonymous));
  }

  @override
  Future<ApiResult<AuthSession>> signInWithGoogle(OAuthCredentials credentials) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _finish(
      _createSession(AuthProviderKind.google).copyWith(
        displayName: 'Google Kullanıcı',
      ),
    );
  }

  @override
  Future<ApiResult<AuthSession>> signInWithApple(OAuthCredentials credentials) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _finish(
      _createSession(AuthProviderKind.apple).copyWith(
        displayName: 'Apple Kullanıcı',
      ),
    );
  }

  @override
  Future<ApiResult<AuthSession>> signInWithEmail(EmailCredentials credentials) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _finish(
      _createSession(AuthProviderKind.email).copyWith(
        email: credentials.email,
        displayName: credentials.email.split('@').first,
      ),
    );
  }

  @override
  Future<ApiResult<AuthSession>> createGuestSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _finish(_createSession(AuthProviderKind.guest, guest: true));
  }

  @override
  Future<ApiResult<AuthSession>> ensureAnonymousSession() =>
      signInAnonymously();

  @override
  Future<ApiResult<AuthSession>> refreshSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _finish(_createSession(AuthProviderKind.guest));
  }

  @override
  Future<ApiResult<bool>> signOut() async {
    await _sessions?.clearSession();
    await _tokens?.clearTokens();
    return const ApiSuccess(true);
  }

  @override
  Future<ApiResult<bool>> deleteAccount() async {
    await _sessions?.clearSession();
    await _tokens?.clearTokens();
    return const ApiSuccess(true);
  }

  @override
  bool get isCurrentUserAnonymous =>
      _sessions?.currentSession?.provider != AuthProviderKind.google &&
      _sessions?.currentSession?.provider != AuthProviderKind.apple &&
      _sessions?.currentSession?.provider != AuthProviderKind.email;

  @override
  bool get hasCurrentIdentity => _sessions?.currentSession != null;

  @override
  String? get currentUserId => _sessions?.currentSession?.userId;

  @override
  List<AccountReauthMethod> get currentReauthMethods {
    final provider = _sessions?.currentSession?.provider;
    return switch (provider) {
      AuthProviderKind.google => const [AccountReauthMethod.google],
      AuthProviderKind.apple => const [AccountReauthMethod.apple],
      AuthProviderKind.email => const [AccountReauthMethod.email],
      _ => const [],
    };
  }

  @override
  String? get currentUserEmail => _sessions?.currentSession?.email;

  @override
  Future<ApiResult<bool>> reauthenticate(
    AccountReauthCredentials credentials,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return const ApiSuccess(true);
  }
}
