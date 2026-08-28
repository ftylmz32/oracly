/// OR-1130 — Active session lifecycle manager.
library;

import 'dart:async';

import 'models/auth_session.dart';
import 'token_manager.dart';

abstract class SessionManager {
  Stream<AuthSession?> get sessionStream;
  AuthSession? get currentSession;
  Future<void> setSession(AuthSession session);
  Future<void> clearSession();
  Future<bool> restoreSession();
}

class InMemorySessionManager implements SessionManager {
  InMemorySessionManager(this._tokenManager);

  final TokenManager _tokenManager;
  AuthSession? _session;
  final _controller = StreamController<AuthSession?>.broadcast();

  @override
  Stream<AuthSession?> get sessionStream => _controller.stream;

  @override
  AuthSession? get currentSession => _session;

  @override
  Future<void> setSession(AuthSession session) async {
    _session = session;
    await _tokenManager.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
    );
    _controller.add(session);
  }

  @override
  Future<void> clearSession() async {
    _session = null;
    await _tokenManager.clearTokens();
    _controller.add(null);
  }

  @override
  Future<bool> restoreSession() async {
    if (!await _tokenManager.hasValidAccessToken()) return false;
    final access = await _tokenManager.getAccessToken();
    if (access == null || access.isEmpty || access.startsWith('mock_')) {
      return false;
    }
    final refresh = await _tokenManager.getRefreshToken();

    _session = AuthSession(
      userId: 'restored',
      provider: AuthProviderKind.guest,
      accessToken: access,
      refreshToken: refresh ?? '',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      isGuest: true,
    );
    _controller.add(_session);
    return true;
  }

  void dispose() => _controller.close();
}
