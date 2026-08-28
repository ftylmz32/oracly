/// Live Firebase Auth. Construct only after [FirebaseAuthBootstrap.isReady].
library;

import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_auth_gateway.dart';
import 'firebase_auth_user.dart';

class LiveFirebaseAuthGateway implements FirebaseAuthGateway {
  LiveFirebaseAuthGateway([FirebaseAuth? auth])
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  bool get isInitialized => true;

  @override
  FirebaseAuthUserSnapshot? get currentUser => _map(_auth.currentUser);

  @override
  Stream<FirebaseAuthUserSnapshot?> authStateChanges() =>
      _auth.authStateChanges().map(_map);

  @override
  Future<String?> currentIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInAnonymously() async {
    return _run(() async {
      final cred = await _auth.signInAnonymously();
      return _require(cred.user);
    });
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _run(() async {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _require(cred.user);
    });
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) async {
    return _run(() async {
      final cred = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: accessToken,
        ),
      );
      return _require(cred.user);
    });
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInWithApple({
    required String idToken,
  }) async {
    return _run(() async {
      final oauth = OAuthProvider('apple.com').credential(idToken: idToken);
      final cred = await _auth.signInWithCredential(oauth);
      return _require(cred.user);
    });
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<FirebaseAuthUserSnapshot> _run(
    Future<FirebaseAuthUserSnapshot> Function() action,
  ) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthGatewayException(e.code, code: e.code);
    }
  }

  FirebaseAuthUserSnapshot _require(User? user) {
    final mapped = _map(user);
    if (mapped == null) {
      throw AuthGatewayException('missing-user', code: 'missing-user');
    }
    return mapped;
  }

  FirebaseAuthUserSnapshot? _map(User? user) {
    if (user == null) return null;
    return FirebaseAuthUserSnapshot(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      isAnonymous: user.isAnonymous,
    );
  }
}
