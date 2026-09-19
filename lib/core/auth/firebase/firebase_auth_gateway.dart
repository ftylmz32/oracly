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

  /// Permanently deletes the signed-in Firebase user. Never a silent logout.
  Future<void> deleteCurrentUser();

  /// Re-proves identity with a fresh Google credential (token-based).
  Future<void> reauthenticateWithGoogle({
    required String idToken,
    String? accessToken,
  });

  /// Native mobile Google reauth via Firebase Auth provider UI.
  Future<void> reauthenticateWithGoogleProvider();

  Future<void> reauthenticateWithApple({required String idToken});

  /// Native mobile Apple reauth via Firebase Auth provider UI.
  Future<void> reauthenticateWithAppleProvider();

  Future<void> reauthenticateWithEmail({
    required String email,
    required String password,
  });
}

class AuthGatewayException implements Exception {
  AuthGatewayException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthGatewayException($code)';
}
