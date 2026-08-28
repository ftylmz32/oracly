/// Cold-start Firebase anonymous session — no login UI, no MockAuth.
library;

import 'dart:async';

import '../network/api_result.dart';
import 'auth_service.dart';
import 'mock_auth_service.dart';
import 'models/auth_session.dart';

abstract final class AnonymousAuthBootstrap {
  AnonymousAuthBootstrap._();

  /// Reuses an existing Firebase user, or signs in anonymously.
  /// Unconfigured auth stays fail-closed. Never uses [MockAuthService].
  /// Network hangs fail open after [timeout] so Splash can still paint.
  static Future<ApiResult<AuthSession>?> ensure(
    AuthService auth, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (auth is MockAuthService) return null;
    try {
      return await auth.ensureAnonymousSession().timeout(timeout);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
