/// Credential / provider reauthentication helpers for [LiveFirebaseAuthGateway].
library;

import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_auth_gateway.dart';

abstract final class LiveFirebaseAuthReauth {
  LiveFirebaseAuthReauth._();

  static Future<void> withCredential(
    FirebaseAuth auth,
    AuthCredential credential,
  ) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        throw AuthGatewayException('no-current-user', code: 'no-current-user');
      }
      await user.reauthenticateWithCredential(credential);
    } on AuthGatewayException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthGatewayException(e.code, code: e.code);
    }
  }

  /// Mobile-preferred path: Firebase launches the native provider UI.
  static Future<void> withProvider(
    FirebaseAuth auth,
    AuthProvider provider,
  ) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        throw AuthGatewayException('no-current-user', code: 'no-current-user');
      }
      await user.reauthenticateWithProvider(provider);
    } on AuthGatewayException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthGatewayException(e.code, code: e.code);
    }
  }
}
