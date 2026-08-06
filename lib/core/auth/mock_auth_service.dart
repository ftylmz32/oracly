/// OR-1130 — Mock auth service — no real OAuth/API calls.
library;

import 'dart:math';

import '../network/api_result.dart';
import 'auth_service.dart';
import 'models/auth_credentials.dart';
import 'models/auth_session.dart';

class MockAuthService implements AuthService {
  MockAuthService();

  final _random = Random();

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

  @override
  Future<ApiResult<AuthSession>> signInAnonymously() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiSuccess(_createSession(AuthProviderKind.anonymous));
  }

  @override
  Future<ApiResult<AuthSession>> signInWithGoogle(OAuthCredentials credentials) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return ApiSuccess(
      _createSession(AuthProviderKind.google).copyWith(
        displayName: 'Google Kullanıcı',
      ),
    );
  }

  @override
  Future<ApiResult<AuthSession>> signInWithApple(OAuthCredentials credentials) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return ApiSuccess(
      _createSession(AuthProviderKind.apple).copyWith(
        displayName: 'Apple Kullanıcı',
      ),
    );
  }

  @override
  Future<ApiResult<AuthSession>> signInWithEmail(EmailCredentials credentials) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiSuccess(
      _createSession(AuthProviderKind.email).copyWith(
        email: credentials.email,
        displayName: credentials.email.split('@').first,
      ),
    );
  }

  @override
  Future<ApiResult<AuthSession>> createGuestSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return ApiSuccess(_createSession(AuthProviderKind.guest, guest: true));
  }

  @override
  Future<ApiResult<AuthSession>> refreshSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return ApiSuccess(_createSession(AuthProviderKind.guest));
  }

  @override
  Future<ApiResult<bool>> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return const ApiSuccess(true);
  }
}
