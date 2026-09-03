/// Maps Firebase Auth codes to user copy. Never exposes provider internals.
library;

import '../../network/network_exception.dart';
import '../auth_copy.dart';
import 'firebase_auth_gateway.dart';

abstract final class FirebaseAuthErrors {
  FirebaseAuthErrors._();

  static NetworkException map(AuthGatewayException error) {
    final code = error.code ?? '';
    if (code.contains('network')) {
      return NetworkException.noConnection();
    }
    if (code == 'no-current-user') {
      return NetworkException.unauthorized(AuthCopy.noCurrentUser);
    }
    if (code.contains('requires-recent-login')) {
      return NetworkException.unauthorized(AuthCopy.requiresRecentLogin);
    }
    if (code.contains('too-many-requests')) {
      return NetworkException(message: AuthCopy.tooManyAttempts);
    }
    if (code.contains('user-not-found') ||
        code.contains('wrong-password') ||
        code.contains('invalid-credential') ||
        code.contains('invalid-email')) {
      return NetworkException.unauthorized(AuthCopy.invalidCredentials);
    }
    return NetworkException.unauthorized(AuthCopy.failed);
  }

  static NetworkException mapDelete(AuthGatewayException error) {
    final code = error.code ?? '';
    if (code.contains('network')) {
      return NetworkException.noConnection();
    }
    if (code == 'no-current-user') {
      return NetworkException.unauthorized(AuthCopy.noCurrentUser);
    }
    if (code.contains('requires-recent-login')) {
      return NetworkException.unauthorized(AuthCopy.requiresRecentLogin);
    }
    if (code.contains('too-many-requests')) {
      return NetworkException(message: AuthCopy.tooManyAttempts);
    }
    return NetworkException.unauthorized(AuthCopy.deleteFailed);
  }
}
