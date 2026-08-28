/// Anonymous Firebase bootstrap — reuse user, fail-closed, never MockAuth.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/anonymous_auth_bootstrap.dart';
import 'package:oracly_new/core/auth/auth_copy.dart';
import 'package:oracly_new/core/auth/auth_service_selection.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_gateway.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_service.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_user.dart';
import 'package:oracly_new/core/auth/firebase/firebase_id_token_manager.dart';
import 'package:oracly_new/core/auth/mock_auth_service.dart';
import 'package:oracly_new/core/auth/session_manager.dart';
import 'package:oracly_new/core/auth/unconfigured_auth_service.dart';

const _idToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.e30.sig';

void main() {
  test('existing Firebase user is reused', () async {
    final gateway = _FakeGateway()
      ..seedUser(
        const FirebaseAuthUserSnapshot(uid: 'uid-existing', isAnonymous: true),
      );
    final tokens = FirebaseIdTokenManager(gateway);
    final auth = FirebaseAuthService(
      gateway: gateway,
      tokens: tokens,
      sessions: InMemorySessionManager(tokens),
    );

    final result = await AnonymousAuthBootstrap.ensure(auth);
    expect(result?.isSuccess, isTrue);
    expect(result?.dataOrNull?.userId, 'uid-existing');
    expect(result?.dataOrNull?.accessToken, _idToken);
    expect(gateway.anonymousSignIns, 0);
    expect(await tokens.getAccessToken(), _idToken);
    auth.dispose();
  });

  test('missing user triggers anonymous sign-in', () async {
    final gateway = _FakeGateway();
    final tokens = FirebaseIdTokenManager(gateway);
    final auth = FirebaseAuthService(
      gateway: gateway,
      tokens: tokens,
      sessions: InMemorySessionManager(tokens),
    );

    final result = await AnonymousAuthBootstrap.ensure(auth);
    expect(result?.isSuccess, isTrue);
    expect(result?.dataOrNull?.userId, 'uid-anon');
    expect(result?.dataOrNull?.accessToken, _idToken);
    expect(gateway.anonymousSignIns, 1);
    expect(await tokens.getAccessToken(), _idToken);
    auth.dispose();
  });

  test('unconfigured Firebase remains fail-closed', () async {
    final auth = UnconfiguredAuthService();
    final result = await AnonymousAuthBootstrap.ensure(auth);
    expect(result?.isFailure, isTrue);
    expect(result?.errorOrNull?.message, AuthCopy.notConfigured);
    expect(auth.isConfigured, isFalse);
  });

  test('release selection does not use MockAuthService', () async {
    final auth = AuthServiceSelection.create(
      productionLike: true,
      firebaseReady: false,
    );
    expect(auth, isA<UnconfiguredAuthService>());
    expect(auth, isNot(isA<MockAuthService>()));
    expect(await AnonymousAuthBootstrap.ensure(MockAuthService()), isNull);
  });
}

class _FakeGateway implements FirebaseAuthGateway {
  final _controller = StreamController<FirebaseAuthUserSnapshot?>.broadcast();
  FirebaseAuthUserSnapshot? _user;
  int anonymousSignIns = 0;

  void seedUser(FirebaseAuthUserSnapshot user) => _user = user;

  @override
  bool get isInitialized => true;

  @override
  FirebaseAuthUserSnapshot? get currentUser => _user;

  @override
  Stream<FirebaseAuthUserSnapshot?> authStateChanges() => _controller.stream;

  @override
  Future<String?> currentIdToken({bool forceRefresh = false}) async {
    if (_user == null) return null;
    return _idToken;
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInAnonymously() async {
    anonymousSignIns++;
    _user = const FirebaseAuthUserSnapshot(uid: 'uid-anon', isAnonymous: true);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInWithEmail({
    required String email,
    required String password,
  }) =>
      signInAnonymously();

  @override
  Future<FirebaseAuthUserSnapshot> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) =>
      signInAnonymously();

  @override
  Future<FirebaseAuthUserSnapshot> signInWithApple({required String idToken}) =>
      signInAnonymously();

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
