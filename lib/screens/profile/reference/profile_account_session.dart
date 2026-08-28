/// Whether Profile may show logout for a real signed-in account.
library;

import '../../../core/auth/auth_service.dart';
import '../../../core/auth/models/auth_session.dart';

bool profileHasRealAccountSession({
  required AuthService auth,
  AuthSession? session,
}) {
  if (!auth.isConfigured) return false;
  if (session == null || session.isExpired) return false;
  if (session.isGuest) return false;
  if (session.provider == AuthProviderKind.anonymous) return false;
  final token = session.accessToken.trim();
  if (token.isEmpty || token.startsWith('mock_')) return false;
  return true;
}
