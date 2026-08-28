/// Testable Firebase Auth surface. Screens never depend on this.
library;

import 'firebase_auth_user.dart';

abstract class FirebaseAuthGateway {
  bool get isInitialized;
  FirebaseAuthUserSnapshot? get currentUser;
  Stream<FirebaseAuthUserSnapshot?> authStateChanges();
  Future<String?> currentIdToken({bool forceRefresh = false});
  Future<FirebaseAuthUserSnapshot> signInAnonymously();
  Future<FirebaseAuthUserSnapshot> signInWithEmail({
    required String email,
    required String password,
  });
  Future<FirebaseAuthUserSnapshot> signInWithGoogle({
    required String idToken,
    String? accessToken,
  });
  Future<FirebaseAuthUserSnapshot> signInWithApple({required String idToken});
  Future<void> signOut();
}

class AuthGatewayException implements Exception {
  AuthGatewayException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthGatewayException($code)';
}
