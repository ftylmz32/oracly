/// Chooses Mock (dev/test), Firebase, or fail-closed unconfigured auth.
library;

import 'auth_service.dart';
import '../data/datasources/local_storage.dart';
import 'firebase/firebase_auth_gateway.dart';
import 'firebase/firebase_auth_service.dart';
import 'mock_auth_service.dart';
import 'session_manager.dart';
import 'token_manager.dart';
import 'unconfigured_auth_service.dart';
import 'user_local_data_isolation.dart';

abstract final class AuthServiceSelection {
  AuthServiceSelection._();

  static AuthService create({
    required bool productionLike,
    required bool firebaseReady,
    FirebaseAuthGateway? gateway,
    TokenManager? tokens,
    SessionManager? sessions,
    LocalStorage? storage,
  }) {
    final isolation =
        storage == null ? null : UserLocalDataIsolation(storage);
    if (firebaseReady && gateway != null && gateway.isInitialized) {
      return FirebaseAuthService(
        gateway: gateway,
        tokens: tokens,
        sessions: sessions,
        isolation: isolation,
      );
    }
    if (productionLike) {
      return UnconfiguredAuthService(tokens: tokens, sessions: sessions);
    }
    return MockAuthService(
      tokens: tokens,
      sessions: sessions,
      isolation: isolation,
    );
  }
}
